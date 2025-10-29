class MessageCreationJob < ApplicationJob
  queue_as :default
  
  # Prevent duplicate job execution for same chat/number
  sidekiq_options lock: :until_executed,
                  on_conflict: :log,
                  lock_args_method: :lock_args

  def self.lock_args(args)
    [args[0], args[2]] # chat_id, number
  end

  def perform(chat_id, body, number)
    chat = Chat.find(chat_id)
    message = chat.messages.find_by(number: number)
    
    if message.nil?
      message = chat.messages.create!(number: number, body: body)
      # Atomic counter update - avoids race conditions
      Chat.increment_counter(:messages_count, chat_id)
      # Searchkick will handle async indexing via callbacks
    end
    
    Rails.logger.info "MessageCreationJob completed: Message #{message.number} for Chat #{chat.id}"
    message.number
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "MessageCreationJob failed: Chat #{chat_id} not found"
    nil # Don't retry if chat doesn't exist
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.warn "MessageCreationJob: Message #{number} already exists for Chat #{chat_id}"
    nil # Idempotent: if message exists, job succeeds
  rescue Searchkick::ImportError, Elasticsearch::Transport::Transport::Errors::ServiceUnavailable => e
    Rails.logger.error "MessageCreationJob: Elasticsearch error: #{e.message}"
    nil # Continue execution even if ES fails; can reindex later
  rescue => e
    Rails.logger.error "MessageCreationJob failed: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e # Re-raise for Sidekiq retry
  end
end

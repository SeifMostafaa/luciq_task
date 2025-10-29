class ChatCreationJob < ApplicationJob
  queue_as :default
  
  sidekiq_options lock: :until_executed, on_conflict: :log, lock_args_method: :lock_args

  def self.lock_args(args)
    [args[0], args[1]]
  end

  def perform(application_id, number)
    application = Application.find(application_id)
    chat = application.chats.find_by(number: number)
    
    if chat.nil?
      chat = application.chats.create!(number: number)
      # Atomic counter update - avoids race conditions
      Application.increment_counter(:chats_count, application_id)
      # Cache the chat ID for faster lookups
      CacheService.cache_chat_id(application.token, chat.number, chat.id)
    end
    
    Rails.logger.info "ChatCreationJob completed: Chat #{chat.number} for Application #{application.token}"
    chat.number
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "ChatCreationJob failed: Application #{application_id} not found"
    nil # Don't retry if application doesn't exist
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.warn "ChatCreationJob: Chat #{number} already exists for Application #{application_id}"
    nil # Idempotent: if chat exists, job succeeds
  rescue => e
    Rails.logger.error "ChatCreationJob failed: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e # Re-raise for Sidekiq retry
  end
end

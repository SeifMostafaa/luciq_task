class CountUpdateJob < ApplicationJob
  queue_as :low_priority

  def perform
    update_applications_counts
    update_chats_counts
  rescue => e
    Rails.logger.error "CountUpdateJob failed: #{e.message}"
    raise e
  end

  private

  def update_applications_counts
    subquery = Chat.select('application_id, COUNT(*) AS cnt').group(:application_id)
    Application.joins("LEFT JOIN (#{subquery.to_sql}) c ON c.application_id = applications.id")
               .update_all("applications.chats_count = COALESCE(c.cnt, 0)")
  end

  def update_chats_counts
    subquery = Message.select('chat_id, COUNT(*) AS cnt').group(:chat_id)
    Chat.joins("LEFT JOIN (#{subquery.to_sql}) m ON m.chat_id = chats.id")
        .update_all("chats.messages_count = COALESCE(m.cnt, 0)")
  end
end


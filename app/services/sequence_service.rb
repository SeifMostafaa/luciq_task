class SequenceService
  def self.next_chat_number(application_token)
    key = "application:#{application_token}:chat_seq"
    
    # Initialize to 0 if key doesn't exist (atomic operation)
    # Rely on DB uniqueness constraints and job idempotency for correctness
    $redis.with do |conn|
      conn.setnx(key, 0)
      conn.incr(key)
    end
  end

  def self.next_message_number(application_token, chat_number)
    key = "chat:#{application_token}:#{chat_number}:msg_seq"
    
    # Initialize to 0 if key doesn't exist (atomic operation)
    # Rely on DB uniqueness constraints and job idempotency for correctness
    $redis.with do |conn|
      conn.setnx(key, 0)
      conn.incr(key)
    end
  end
end

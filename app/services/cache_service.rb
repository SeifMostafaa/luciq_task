class CacheService
  CACHE_TTL = 3600
  LOCK_TTL = 10
  LOCK_WAIT_TIMEOUT = 5
  LOCK_RETRY_DELAY = 0.05

  # Find application ID by token with Redis caching
  def self.application_id_by_token(token)
    key = "app:token:#{token}:id"
    
    cached_id = $redis.with { |conn| conn.get(key) }
    
    if cached_id
      cached_id.to_i
    else
      # Use lock to prevent cache stampede (thundering herd)
      fetch_with_lock(key) do
        Application.where(token: token).pick(:id)
      end
    end
  end

  # Find chat ID by application token and chat number with Redis caching
  def self.chat_id_by_token_and_number(application_token, chat_number)
    key = "chat:#{application_token}:#{chat_number}:id"
    
    cached_id = $redis.with { |conn| conn.get(key) }
    
    if cached_id
      cached_id.to_i
    else
      # Use lock to prevent cache stampede (thundering herd)
      fetch_with_lock(key) do
        Chat.joins(:application)
            .where(applications: { token: application_token }, chats: { number: chat_number })
            .pick(:id)
      end
    end
  end

  private

  # Fetch value with distributed lock to prevent cache stampede
  def self.fetch_with_lock(cache_key)
    lock_key = "#{cache_key}:lock"
    start_time = Time.current
    
    loop do
      acquired = $redis.with { |conn| conn.set(lock_key, '1', nx: true, ex: LOCK_TTL) }
      
      if acquired
        begin
          # We got the lock - fetch from DB and cache
          value = yield
          if value
            $redis.with { |conn| conn.setex(cache_key, CACHE_TTL, value) }
          end
          return value
        ensure
          # Always release lock
          $redis.with { |conn| conn.del(lock_key) }
        end
      else
        # Another process has the lock - wait and check cache
        sleep(LOCK_RETRY_DELAY)
        
        # Check if cache was populated by lock holder
        cached_value = $redis.with { |conn| conn.get(cache_key) }
        return cached_value.to_i if cached_value
        
        # Timeout protection - avoid infinite wait
        if Time.current - start_time > LOCK_WAIT_TIMEOUT
          Rails.logger.warn "Cache lock timeout for key: #{cache_key}, falling back to DB"
          # Fallback to DB query without caching (let lock holder cache it)
          return yield
        end
      end
    end
  end

  # Cache application ID after creation
  def self.cache_application_id(token, id)
    key = "app:token:#{token}:id"
    $redis.with { |conn| conn.setex(key, CACHE_TTL, id) }
  end

  # Cache chat ID after creation
  def self.cache_chat_id(application_token, chat_number, chat_id)
    key = "chat:#{application_token}:#{chat_number}:id"
    $redis.with { |conn| conn.setex(key, CACHE_TTL, chat_id) }
  end

  # Invalidate application cache
  def self.invalidate_application(token)
    key = "app:token:#{token}:id"
    $redis.with { |conn| conn.del(key) }
  end

  # Invalidate chat cache
  def self.invalidate_chat(application_token, chat_number)
    key = "chat:#{application_token}:#{chat_number}:id"
    $redis.with { |conn| conn.del(key) }
  end
end


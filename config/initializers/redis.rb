
$redis = ConnectionPool.new(size: ENV.fetch('RAILS_MAX_THREADS', 5).to_i, timeout: 5) do
  Redis.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    timeout: 1,
    reconnect_attempts: 3,
    reconnect_delay: 0.5,
    reconnect_delay_max: 2.0
  )
end

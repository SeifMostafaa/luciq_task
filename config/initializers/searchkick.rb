# config/initializers/searchkick.rb
Searchkick.client_options = {
  retry_on_failure: true,
  transport_options: {
    request: {
      timeout: 60,      # Increase from default 30 seconds
      open_timeout: 10
    }
  },
  log: false  # Disable verbose Elasticsearch logs
}

# Enable async indexing using background jobs (Sidekiq)
Searchkick.callbacks = :async
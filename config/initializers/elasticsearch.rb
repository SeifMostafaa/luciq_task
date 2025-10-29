# config/initializers/elasticsearch.rb
es_host = ENV['ELASTICSEARCH_URL'] || 'localhost:9200'

Elasticsearch::Model.client = Elasticsearch::Client.new(
  host: es_host,
  retry_on_failure: 5,
  reload_connections: true,
  resurrect_after: 30,
  transport_options: {
    request: { timeout: 60 },
    ssl: { verify: false }
  },
  log: false  # Disable verbose Elasticsearch logs
)
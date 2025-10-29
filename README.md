# Chat System API

A scalable, high-performance chat system built with Ruby on Rails. This system supports multiple applications, each with multiple chats, and provides full-text search capabilities powered by Elasticsearch.

## Features

- **Multi-tenant Architecture**: Each application has a unique token and can manage multiple chats
- **Sequential Numbering**: Chats and messages are numbered sequentially per application/chat using Redis atomic counters
- **Asynchronous Processing**: Chat and message creation happens asynchronously via Sidekiq for high throughput
- **Full-Text Search**: Search through message bodies with partial matching using Elasticsearch
- **Race Condition Protection**: Redis-based atomic counters and database unique constraints prevent duplicates
- **Idempotent Jobs**: Jobs are designed to be safely retried without side effects
- **Count Caching**: Applications and chats maintain cached counts with hourly reconciliation

## Architecture

- **Web Framework**: Ruby on Rails 7.1
- **Database**: MySQL 8.0
- **Cache/Queue**: Redis 7
- **Search Engine**: Elasticsearch 8.x
- **Background Jobs**: Sidekiq with unique job locks
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker
- Docker Compose

That's it! Everything else runs in containers.

## Quick Start

1. **Clone the repository** (if applicable)

2. **Start the entire stack**:
   ```bash
   docker-compose up
   ```

   This command will:
   - Build the Rails application image
   - Start MySQL database
   - Start Redis server
   - Start Elasticsearch
   - Create and migrate database automatically
   - Seed sample data (only if database is empty)
   - Start the Rails web server (port 3000)
   - Start Sidekiq workers

3. **Wait for services to be healthy**

   The first startup may take a few minutes as Docker downloads images and builds the application. Watch the logs until you see:
   ```
   web_1           | * Listening on http://0.0.0.0:3000
   sidekiq_1       | Sidekiq 7.x.x starting
   ```

4. **Verify the system is running**:
   ```bash
   curl http://localhost:3000/up
   ```

## Sample Data

On first startup, the system automatically seeds sample data including:
- **5 Applications** with realistic names (Customer Support Platform, Sales Team Workspace, etc.)
- **46 Chats** distributed across applications
- **500+ Messages** with conversational context

The seed data is only created if the database is empty, so you can safely restart containers without duplicating data.

### View Sample Data

```bash
# Get first application's token from logs, or:
docker-compose exec web bundle exec rails runner "puts Application.first.token"

# Then use it to explore:
TOKEN="<your_token_here>"
curl http://localhost:3000/applications/$TOKEN
curl http://localhost:3000/applications/$TOKEN/chats
curl http://localhost:3000/applications/$TOKEN/chats/1/messages
curl "http://localhost:3000/applications/$TOKEN/chats/1/messages/search?q=hello"
```

## API Endpoints

### Applications

#### Create Application
```bash
POST /applications
Content-Type: application/json

{
  "application": {
    "name": "My App"
  }
}

Response (201 Created):
{
  "token": "a1b2c3d4e5f6...",
  "name": "My App"
}
```

#### Get Application
```bash
GET /applications/:token

Response (200 OK):
{
  "token": "a1b2c3d4e5f6...",
  "name": "My App",
  "chats_count": 5,
  "created_at": "2025-10-27T12:00:00.000Z"
}
```

#### Update Application
```bash
PATCH /applications/:token
Content-Type: application/json

{
  "application": {
    "name": "Updated Name"
  }
}

Response (200 OK):
{
  "token": "a1b2c3d4e5f6...",
  "name": "Updated Name",
  "chats_count": 5,
  "created_at": "2025-10-27T12:00:00.000Z"
}
```

### Chats

#### Create Chat (Async)
```bash
POST /applications/:application_token/chats

Response (202 Accepted):
{
  "job_id": "abc123...",
  "number": 1
}
```

Note: The chat number is returned immediately and guaranteed to be unique. The chat is persisted asynchronously.

#### List Chats
```bash
GET /applications/:application_token/chats

Response (200 OK):
[
  {
    "number": 1,
    "messages_count": 10,
    "created_at": "2025-10-27T12:00:00.000Z"
  },
  {
    "number": 2,
    "messages_count": 5,
    "created_at": "2025-10-27T12:05:00.000Z"
  }
]
```

#### Get Chat
```bash
GET /applications/:application_token/chats/:number

Response (200 OK):
{
  "number": 1,
  "messages_count": 10,
  "created_at": "2025-10-27T12:00:00.000Z"
}
```

### Messages

#### Create Message (Async)
```bash
POST /applications/:application_token/chats/:chat_number/messages
Content-Type: application/json

{
  "message": {
    "body": "Hello, world!"
  }
}

Response (202 Accepted):
{
  "job_id": "xyz789...",
  "number": 1
}
```

Note: The message number is returned immediately and guaranteed to be unique. The message is persisted and indexed asynchronously.

#### List Messages
```bash
GET /applications/:application_token/chats/:chat_number/messages

Response (200 OK):
[
  {
    "number": 1,
    "body": "Hello, world!",
    "created_at": "2025-10-27T12:00:00.000Z"
  },
  {
    "number": 2,
    "body": "How are you?",
    "created_at": "2025-10-27T12:01:00.000Z"
  }
]
```

#### Get Message
```bash
GET /applications/:application_token/chats/:chat_number/messages/:number

Response (200 OK):
{
  "number": 1,
  "body": "Hello, world!",
  "created_at": "2025-10-27T12:00:00.000Z"
}
```

#### Update Message
```bash
PATCH /applications/:application_token/chats/:chat_number/messages/:number
Content-Type: application/json

{
  "message": {
    "body": "Updated message text"
  }
}

Response (200 OK):
{
  "number": 1,
  "body": "Updated message text",
  "created_at": "2025-10-27T12:00:00.000Z"
}
```

#### Search Messages
```bash
GET /applications/:application_token/chats/:chat_number/messages/search?q=hello

Response (200 OK):
[
  {
    "number": 1,
    "body": "Hello, world!",
    "created_at": "2025-10-27T12:00:00.000Z"
  },
  {
    "number": 3,
    "body": "Hello again!",
    "created_at": "2025-10-27T12:10:00.000Z"
  }
]
```

Note: Search supports partial word matching (e.g., "hel" will match "hello").

## Example Usage

```bash
# Create an application
APP_TOKEN=$(curl -X POST http://localhost:3000/applications \
  -H "Content-Type: application/json" \
  -d '{"application": {"name": "Test App"}}' \
  | jq -r '.token')

echo "Application token: $APP_TOKEN"

# Create a chat
CHAT_NUMBER=$(curl -X POST http://localhost:3000/applications/$APP_TOKEN/chats \
  | jq -r '.number')

echo "Chat number: $CHAT_NUMBER"

# Wait a moment for async processing
sleep 1

# Create a message
MESSAGE_NUMBER=$(curl -X POST http://localhost:3000/applications/$APP_TOKEN/chats/$CHAT_NUMBER/messages \
  -H "Content-Type: application/json" \
  -d '{"message": {"body": "Hello from the API!"}}' \
  | jq -r '.number')

echo "Message number: $MESSAGE_NUMBER"

# Wait for indexing
sleep 2

# Search messages
curl "http://localhost:3000/applications/$APP_TOKEN/chats/$CHAT_NUMBER/messages/search?q=Hello"

# List all messages
curl "http://localhost:3000/applications/$APP_TOKEN/chats/$CHAT_NUMBER/messages"
```

## Technical Details

### Numbering Strategy

- **Sequential Numbers**: Chats are numbered 1, 2, 3... per application. Messages are numbered 1, 2, 3... per chat.
- **Redis Atomic Counters**: Numbers are allocated immediately using Redis INCR for O(1) atomic operations.
- **Database Constraints**: Unique composite indexes on `(application_id, number)` and `(chat_id, number)` prevent duplicates.
- **Backfilling**: If Redis keys are lost, they're automatically backfilled from the database on next allocation.

### Asynchronous Processing

- **Immediate Response**: API endpoints return numbers and job IDs immediately without waiting for database writes.
- **Sidekiq Workers**: Background jobs persist data to MySQL and index to Elasticsearch.
- **Idempotency**: Jobs use `find_or_create_by!` and are safe to retry multiple times.
- **Unique Jobs**: Duplicate jobs are prevented using `sidekiq-unique-jobs` gem.

### Count Caching

- **Real-time Updates**: Counts are incremented when chats/messages are created.
- **Hourly Reconciliation**: A scheduled job runs every hour to reconcile counts from the database, ensuring counts are never more than 1 hour stale.
- **Eventual Consistency**: Counts may lag briefly during high load but will converge.

### Race Condition Protection

- **Redis Atomicity**: INCR operations are atomic, preventing number collisions.
- **Database Constraints**: Unique indexes catch any race conditions that bypass Redis.
- **Job Locking**: Unique job locks prevent concurrent execution of duplicate jobs.

### Search Implementation

- **Searchkick**: Wraps Elasticsearch with a simple Ruby interface.
- **Word Start Matching**: Partial matching on word boundaries (e.g., "hel" matches "hello world").
- **Automatic Indexing**: Messages are indexed asynchronously after creation.
- **Reindexing**: Can rebuild the entire index with `Message.reindex`.

## Development Commands

### Access Rails Console
```bash
docker-compose exec web bundle exec rails console
```

### Run Migrations
```bash
docker-compose exec web bundle exec rails db:migrate
```

### Seed Database (Manual)
```bash
# Only seeds if database is empty
docker-compose exec web bundle exec rails db:seed

# View seed summary
docker-compose exec web bundle exec rails db:seed_summary

# Force reseed (deletes all data)
docker-compose exec web bundle exec rails db:reseed
```

### Check Elasticsearch
```bash
# Check health
docker-compose exec web bundle exec rails elasticsearch:health

# Check indexing status
docker-compose exec web bundle exec rails elasticsearch:status

# Reindex all messages
docker-compose exec web bundle exec rails elasticsearch:reindex
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f sidekiq
```

### Reindex Elasticsearch
```bash
docker-compose exec web bundle exec rails elasticsearch:reindex
# Or using runner:
docker-compose exec web bundle exec rails runner "Message.reindex"
```

### Stop Services
```bash
docker-compose down
```

### Reset Everything
```bash
docker-compose down -v
docker-compose up --build
```

## Running Tests

```bash
# Set up test database (first time only)
docker-compose exec web bundle exec rails db:test:prepare

# Run all tests with RSpec
docker-compose exec web bundle exec rspec

# Run specific test file
docker-compose exec web bundle exec rspec spec/controllers/applications_controller_spec.rb

# Run specific test
docker-compose exec web bundle exec rspec spec/controllers/applications_controller_spec.rb:10
```

## Environment Variables

The following environment variables can be configured in `docker-compose.yml`:

- `DATABASE_HOST`: MySQL host (default: `db`)
- `DATABASE_USERNAME`: MySQL username (default: `root`)
- `DATABASE_PASSWORD`: MySQL password (default: `password`)
- `DATABASE_PORT`: MySQL port (default: `3306`)
- `REDIS_URL`: Redis connection URL (default: `redis://redis:6379/0`)
- `ELASTICSEARCH_URL`: Elasticsearch URL (default: `http://elasticsearch:9200`)
- `RAILS_ENV`: Rails environment (default: `development`)
- `SIDEKIQ_CONCURRENCY`: Number of Sidekiq threads (default: `5`)

## Monitoring

### Sidekiq Web UI

You can add Sidekiq's web UI by mounting it in `config/routes.rb`:

```ruby
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq'
```

Then access it at http://localhost:3000/sidekiq

### Elasticsearch Health

```bash
curl http://localhost:9200/_cluster/health?pretty
```

### Redis Info

```bash
docker-compose exec redis redis-cli INFO
```

### Database Status

```bash
docker-compose exec db mysql -uroot -ppassword -e "SHOW DATABASES; SHOW PROCESSLIST;"
```

## Performance Considerations

- **Horizontal Scaling**: Multiple web and Sidekiq containers can run in parallel.
- **Connection Pooling**: Rails manages database connection pools automatically.
- **Redis Memory**: Monitor Redis memory usage; sequences use minimal space but can grow with many applications.
- **Elasticsearch Tuning**: For production, tune heap size, shards, and replicas based on data volume.
- **Database Indexes**: All foreign keys and search columns are indexed for optimal query performance.

## Troubleshooting

### Services won't start
- Ensure Docker daemon is running
- Check if ports 3000, 3307, 6380, 9200 are available
- Run `docker-compose down -v` to clean up and restart

### Messages not searchable
- Wait 1-2 seconds after message creation for Elasticsearch indexing
- Check Elasticsearch status: `docker-compose exec web bundle exec rails elasticsearch:health`
- Check indexing status: `docker-compose exec web bundle exec rails elasticsearch:status`
- Rebuild index: `docker-compose exec web bundle exec rails elasticsearch:reindex`
- Verify Elasticsearch is running: `curl http://localhost:9200/_cluster/health`

### Counts are incorrect
- Counts are eventually consistent and reconciled hourly
- Force reconciliation: `docker-compose exec web bundle exec rails runner "CountUpdateJob.perform_now"`

### Jobs not processing
- Check Sidekiq logs: `docker-compose logs -f sidekiq`
- Verify Redis connection: `docker-compose exec redis redis-cli PING`

## Production Deployment

For production deployment:

1. Update `Dockerfile` to use production settings
2. Set `RAILS_ENV=production`
3. Configure proper database credentials
4. Set up SSL/TLS termination (e.g., nginx reverse proxy)
5. Configure log aggregation (e.g., Fluentd, Logstash)
6. Set up monitoring (e.g., New Relic, Datadog)
7. Scale web and sidekiq services as needed
8. Use managed services for MySQL, Redis, and Elasticsearch

## License

This project is provided as-is for evaluation purposes.

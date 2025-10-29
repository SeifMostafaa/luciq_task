# lib/tasks/elasticsearch.rake
namespace :elasticsearch do
  desc "Check Elasticsearch health"
  task health: :environment do
    begin
      client = Searchkick.client
      health = client.cluster.health
      
      puts "✅ Elasticsearch is running!"
      puts "  Cluster: #{health['cluster_name']}"
      puts "  Status: #{health['status']}"
      puts "  Nodes: #{health['number_of_nodes']}"
      puts "  Active Shards: #{health['active_shards']}"
    rescue => e
      puts "❌ Elasticsearch is not available!"
      puts "  Error: #{e.message}"
      exit 1
    end
  end

  desc "Reindex all messages"
  task reindex: :environment do
    puts "🔍 Reindexing messages..."
    
    begin
      Message.reindex
      puts "✅ Successfully reindexed #{Message.count} messages"
    rescue => e
      puts "❌ Reindexing failed: #{e.message}"
      puts "   Make sure Elasticsearch is running: docker-compose ps elasticsearch"
      exit 1
    end
  end

  desc "Show indexing status"
  task status: :environment do
    puts "📊 Message Indexing Status:"
    puts "  Total messages in database: #{Message.count}"
    
    begin
      # Try to search for all messages
      search_result = Message.search("*", load: false)
      puts "  Messages in Elasticsearch: #{search_result.total_count}"
      
      if Message.count == search_result.total_count
        puts "  ✅ All messages are indexed!"
      else
        puts "  ⚠️  Some messages are not indexed yet"
        puts "     Run: rails elasticsearch:reindex"
      end
    rescue => e
      puts "  ❌ Cannot connect to Elasticsearch: #{e.message}"
      puts "     Run: docker-compose ps elasticsearch"
    end
  end
end


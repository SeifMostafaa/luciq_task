# db/seeds.rb
# Seeds with logical data for the chat system
# Only runs if tables are empty (idempotent)

puts "🌱 Starting seed process..."

# Check if data already exists
if Application.exists?
  puts "⏭️  Database already contains data. Skipping seeds."
  exit 0
end

puts "📝 Creating seed data..."

# Clear Redis sequences to ensure consistency
puts "  Clearing Redis sequences..."
$redis.flushdb

# Create Applications with meaningful names
applications_data = [
  { name: "Customer Support Platform", chats: 15 },
  { name: "Sales Team Workspace", chats: 8 },
  { name: "Product Development Hub", chats: 12 },
  { name: "Marketing Collaboration", chats: 6 },
  { name: "HR Management System", chats: 5 }
]

applications_data.each_with_index do |app_data, index|
  puts "\n  Creating Application #{index + 1}/#{applications_data.length}: #{app_data[:name]}"
  
  application = Application.create!(
    name: app_data[:name]
  )
  
  puts "    ✓ Token: #{application.token}"
  
  # Create chats for this application
  app_data[:chats].times do |chat_index|
    chat_number = chat_index + 1
    
    chat = application.chats.create!(
      number: chat_number
    )
    
    # Create messages for this chat (varying amounts for realism)
    message_count = rand(5..20)
    
    message_topics = [
      ["Hi there!", "Hello! How can I help you today?", "I have a question about...", "Sure, I'd be happy to help!"],
      ["Welcome!", "Thanks for reaching out", "What can I assist with?", "Let me check that for you"],
      ["Good morning!", "Good morning! What brings you here?", "I need some information", "Absolutely, here's what I found"],
      ["Hey team", "What's the status update?", "Working on it now", "Should be done by EOD"],
      ["Quick question", "Go ahead!", "How do we handle...", "Here's the process"],
      ["Meeting reminder", "Thanks for the heads up", "I'll be there", "See you soon"],
      ["Project update", "Looks good!", "Any blockers?", "None at the moment"],
      ["Bug report", "Thanks for reporting", "I'll investigate", "Fixed in latest build"],
      ["Feature request", "Interesting idea", "Let me discuss with the team", "We'll prioritize this"],
      ["Customer feedback", "Appreciate the input", "We're working on improvements", "Update coming next week"]
    ]
    
    topic = message_topics.sample
    
    message_count.times do |msg_index|
      message_number = msg_index + 1
      
      # Use topic messages if available, otherwise generate generic ones
      body = if msg_index < topic.length
        topic[msg_index]
      else
        responses = [
          "Thanks for the update!",
          "That makes sense.",
          "I understand.",
          "Great, thanks!",
          "Perfect, appreciate it.",
          "Got it, thank you.",
          "Sounds good!",
          "Will do.",
          "Noted.",
          "Thanks for clarifying."
        ]
        responses.sample
      end
      
      chat.messages.create!(
        number: message_number,
        body: body
      )
    end
    
    # Update messages_count
    chat.update_column(:messages_count, message_count)
    
    print "."
  end
  
  # Update chats_count
  application.update_column(:chats_count, app_data[:chats])
  puts "\n    ✓ Created #{app_data[:chats]} chats with messages"
end

# Reindex Elasticsearch
puts "\n🔍 Indexing messages in Elasticsearch..."
begin
  Message.reindex
  puts "  ✓ Elasticsearch indexing complete"
rescue => e
  puts "  ⚠️  Elasticsearch indexing failed (service may not be ready): #{e.message}"
  puts "  You can reindex later with: docker-compose exec web rails runner 'Message.reindex'"
end

# Display summary
puts "\n📊 Seed Summary:"
puts "  Applications: #{Application.count}"
puts "  Chats: #{Chat.count}"
puts "  Messages: #{Message.count}"

puts "\n✅ Seeding complete!"
puts "\n📝 Sample Application Tokens:"
Application.limit(3).each do |app|
  puts "  #{app.name}: #{app.token}"
end

puts "\n💡 Test the API with:"
first_app = Application.first
if first_app
  puts "  curl http://localhost:3000/applications/#{first_app.token}"
  first_chat = first_app.chats.first
  if first_chat
    puts "  curl http://localhost:3000/applications/#{first_app.token}/chats/#{first_chat.number}/messages"
    puts "  curl 'http://localhost:3000/applications/#{first_app.token}/chats/#{first_chat.number}/search?q=hello'"
  end
end

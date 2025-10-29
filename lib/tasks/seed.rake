# lib/tasks/seed.rake
namespace :db do
  desc "Reset and reseed the database (clears all data)"
  task reseed: :environment do
    if Rails.env.production?
      puts "❌ Cannot reseed in production environment"
      exit 1
    end

    puts "⚠️  This will delete all existing data!"
    puts "Press Ctrl+C to cancel, or press Enter to continue..."
    STDIN.gets

    puts "🗑️  Clearing database..."
    Message.delete_all
    Chat.delete_all
    Application.delete_all

    puts "🗑️  Clearing Redis..."
    $redis.flushdb

    puts "🌱 Running seeds..."
    Rake::Task['db:seed'].invoke

    puts "✅ Database reseeded successfully!"
  end

  desc "Show seed data summary"
  task seed_summary: :environment do
    puts "\n📊 Database Summary:"
    puts "  Applications: #{Application.count}"
    puts "  Chats: #{Chat.count}"
    puts "  Messages: #{Message.count}"
    
    if Application.any?
      puts "\n📝 Sample Applications:"
      Application.limit(5).each do |app|
        puts "  #{app.name}"
        puts "    Token: #{app.token}"
        puts "    Chats: #{app.chats_count}"
        puts "    First chat: http://localhost:3000/applications/#{app.token}/chats/1/messages" if app.chats.any?
        puts ""
      end
    else
      puts "\n  No data found. Run 'rails db:seed' to create sample data."
    end
  end
end


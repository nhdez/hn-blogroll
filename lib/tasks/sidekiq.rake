namespace :sidekiq do
  desc "Check if Sidekiq is working properly"
  task :test => :environment do
    puts "Testing Sidekiq..."
    
    # Check if Redis is accessible
    begin
      redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
      redis.ping
      puts "✅ Redis connection: OK"
    rescue => e
      puts "❌ Redis connection failed: #{e.message}"
      exit 1
    end
    
    # Check Sidekiq stats
    require 'sidekiq/api'
    stats = Sidekiq::Stats.new
    puts "📊 Sidekiq Stats:"
    puts "  - Enqueued: #{stats.enqueued}"
    puts "  - Failed: #{stats.failed}"
    puts "  - Processed: #{stats.processed}"
    puts "  - Workers: #{stats.workers_size}"
    puts "  - Processes: #{stats.processes_size}"
    
    # List queues
    puts "📋 Queues:"
    Sidekiq::Queue.all.each do |queue|
      puts "  - #{queue.name}: #{queue.size} jobs"
    end
    
    # Enqueue a test job
    puts "🚀 Enqueueing test job..."
    TestJob.perform_async("Hello from Sidekiq test!")
    puts "Test job enqueued. Check /sidekiq to see if it processes."
  end
  
  desc "Clear all Sidekiq queues"
  task :clear => :environment do
    require 'sidekiq/api'
    
    puts "Clearing all Sidekiq queues..."
    Sidekiq::Queue.all.each do |queue|
      puts "Clearing queue: #{queue.name} (#{queue.size} jobs)"
      queue.clear
    end
    
    puts "Clearing retry set..."
    Sidekiq::RetrySet.new.clear
    
    puts "Clearing scheduled set..."
    Sidekiq::ScheduledSet.new.clear
    
    puts "All queues cleared!"
  end
end
class TestJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3

  def perform(message)
    Rails.logger.info "TestJob executed: #{message}"
    puts "TestJob executed: #{message}"
    
    # Simple test that doesn't require external dependencies
    sleep 2
    
    Rails.logger.info "TestJob completed successfully"
    puts "TestJob completed successfully"
  end
end
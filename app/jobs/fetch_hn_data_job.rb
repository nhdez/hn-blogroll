class FetchHnDataJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3
  
  def perform
    HackerNewsParser.new.fetch_and_process
  rescue StandardError => e
    Rails.logger.error "Failed to fetch HN data: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
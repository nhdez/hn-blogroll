class FetchHnDataJob < ApplicationJob
  queue_as :default
  
  def perform
    HackerNewsParser.new.fetch_and_process
  rescue StandardError => e
    logger.error "Failed to fetch HN data: #{e.message}"
    logger.error e.backtrace.join("\n")
    raise e
  end
end
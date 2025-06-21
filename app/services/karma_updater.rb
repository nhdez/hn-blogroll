class KarmaUpdater
  include HTTParty
  
  attr_reader :blog
  
  def initialize(blog)
    @blog = blog
  end
  
  def update_karma
    return unless blog.username.present?
    
    Rails.logger.info "Updating karma for #{blog.username}"
    
    begin
      karma = fetch_user_karma
      
      if karma
        blog.update!(karma: karma)
        Rails.logger.info "Updated karma for #{blog.username}: #{karma}"
      else
        Rails.logger.warn "Could not fetch karma for #{blog.username}"
      end
      
      karma
    rescue StandardError => e
      Rails.logger.error "Failed to update karma for #{blog.username}: #{e.message}"
      raise e
    end
  end
  
  private
  
  def fetch_user_karma
    # Use HN's API to get user information
    api_url = "https://hacker-news.firebaseio.com/v0/user/#{blog.username}.json"
    
    response = HTTParty.get(api_url, timeout: 10)
    
    unless response.success?
      Rails.logger.warn "HN API returned #{response.code} for user #{blog.username}"
      return nil
    end
    
    user_data = JSON.parse(response.body)
    
    if user_data && user_data['karma']
      user_data['karma']
    else
      Rails.logger.warn "No karma data found for user #{blog.username}"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse HN API response for #{blog.username}: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Error fetching karma for #{blog.username}: #{e.message}"
    nil
  end
end
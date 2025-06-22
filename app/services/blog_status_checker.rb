require 'net/http'
require 'timeout'

class BlogStatusChecker
  include HTTParty
  
  attr_reader :blog
  
  def initialize(blog)
    @blog = blog
  end
  
  def check_and_update_status
    Rails.logger.info "Checking status for #{blog.username}: #{blog.hyperlink}"
    
    begin
      is_online = check_url_status(blog.hyperlink)
      
      blog.update!(
        is_online: is_online,
        online_last_check: Time.current
      )
      
      Rails.logger.info "Status updated for #{blog.username}: #{is_online ? 'online' : 'offline'}"
      
      is_online
    rescue StandardError => e
      Rails.logger.error "Failed to check status for #{blog.username}: #{e.message}"
      
      # Mark as offline if we can't check
      blog.update!(
        is_online: false,
        online_last_check: Time.current
      )
      
      raise e
    end
  end
  
  private
  
  def check_url_status(url)
    # Follow redirects but limit to prevent infinite loops
    response = HTTParty.get(url, 
      timeout: 15,
      follow_redirects: true,
      limit: 5,
      headers: {
        'User-Agent' => 'HN-Blogroll-Bot/1.0 (Status Checker)'
      }
    )
    
    # Consider successful if we get any 2xx response
    success = response.code >= 200 && response.code < 300
    
    # Also check if we got a reasonable response
    if success && response.body.present?
      # Basic check for HTML content
      is_html = response.headers['content-type']&.include?('text/html') || 
                response.body.include?('<html') || 
                response.body.include?('<HTML')
      
      # If it's HTML, check for basic structure
      if is_html
        success = response.body.length > 100 # Reasonable minimum for a blog
      end
    end
    
    Rails.logger.debug "Status check for #{url}: #{response.code} - #{success ? 'online' : 'offline'}"
    
    success
  rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "Timeout checking #{url}: #{e.message}"
    false
  rescue SocketError => e
    Rails.logger.warn "DNS/Socket error checking #{url}: #{e.message}"
    false
  rescue StandardError => e
    Rails.logger.warn "Error checking #{url}: #{e.message}"
    false
  end
end
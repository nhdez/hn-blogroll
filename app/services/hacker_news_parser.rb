class HackerNewsParser
  include HTTParty
  
  BASE_URL = "https://news.ycombinator.com/item?id=36575081"
  
  def initialize
    @processed_count = 0
    @errors = []
  end
  
  def fetch_and_process
    Rails.logger.info "Starting HN data fetch"
    
    blogs_data = fetch_all_pages(BASE_URL)
    process_blogs_data(blogs_data)
    
    Rails.logger.info "HN data fetch completed. Processed: #{@processed_count}, Errors: #{@errors.size}"
    
    { processed: @processed_count, errors: @errors }
  end
  
  private
  
  def fetch_all_pages(url, depth = 0)
    return [] if depth > 50 # Prevent infinite recursion
    
    Rails.logger.info "Fetching page: #{url} (depth: #{depth})"
    
    response = HTTParty.get(url, timeout: 30)
    raise "HTTP #{response.code}" unless response.success?
    
    parsed_html = Nokogiri::HTML(response.body)
    blogs_data = extract_blogs_from_page(parsed_html)
    
    # Check for more pages
    more_link = parsed_html.at('a.morelink')
    if more_link && more_link['href']
      next_url = URI.join(url, more_link['href']).to_s
      blogs_data += fetch_all_pages(next_url, depth + 1)
    end
    
    blogs_data
  rescue StandardError => e
    Rails.logger.error "Failed to fetch page #{url}: #{e.message}"
    @errors << { url: url, error: e.message }
    []
  end
  
  def extract_blogs_from_page(parsed_html)
    blogs_data = []
    rows = parsed_html.css('tr.athing.comtr')
    
    rows.each do |row|
      # Skip nested comments (indented)
      next if row.at_css('td.ind')&.[]('indent')&.to_i&.> 0
      
      blog_data = extract_blog_from_row(row)
      blogs_data << blog_data if blog_data && valid_blog_data?(blog_data)
    end
    
    blogs_data
  end
  
  def extract_blog_from_row(row)
    username = row.css('a.hnuser').text&.strip
    return nil if username.blank?
    
    comment_element = row.css('span.commtext.c00').first
    return nil unless comment_element
    
    # Extract links from the comment
    links = comment_element.css('a[rel="nofollow noreferrer"]')
    return nil if links.empty?
    
    primary_link = links.first['href']
    return nil unless valid_url?(primary_link)
    
    # Clean up description
    description = comment_element.inner_html
    description = ActionController::Base.helpers.sanitize(description, tags: [])
    description = clean_description(description, primary_link)
    
    {
      username: username,
      description: description.strip,
      hyperlink: primary_link
    }
  rescue StandardError => e
    Rails.logger.warn "Failed to extract blog from row: #{e.message}"
    nil
  end
  
  def clean_description(description, link)
    # Remove the link URL from the beginning if it appears there
    description = description.sub(/^#{Regexp.escape(link)}\s*/, '')
    
    # Remove common prefixes
    description = description.sub(/^[:\-\s]+/, '')
    
    # Truncate if too long
    description.truncate(500)
  end
  
  def valid_blog_data?(data)
    return false unless data[:username].present?
    return false unless data[:hyperlink].present?
    return false unless data[:description].present?
    return false unless valid_url?(data[:hyperlink])
    
    # Filter out obvious non-blogs
    domain = URI.parse(data[:hyperlink]).host.downcase rescue nil
    return false unless domain
    
    # Skip social media, forums, etc.
    excluded_domains = %w[
      twitter.com x.com facebook.com linkedin.com instagram.com
      reddit.com news.ycombinator.com stackoverflow.com
      github.com gitlab.com
      youtube.com vimeo.com
      amazon.com
    ]
    
    !excluded_domains.any? { |excluded| domain.include?(excluded) }
  end
  
  def valid_url?(url)
    return false unless url.present?
    
    begin
      uri = URI.parse(url)
      uri.scheme.present? && uri.host.present? && %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end
  end
  
  def process_blogs_data(blogs_data)
    blogs_data.each do |blog_data|
      begin
        blog = Blog.find_or_initialize_by(username: blog_data[:username])
        
        if blog.new_record?
          blog.assign_attributes(
            description: blog_data[:description],
            hyperlink: blog_data[:hyperlink],
            is_approved: false # Require manual approval for new blogs
          )
          
          if blog.save
            @processed_count += 1
            Rails.logger.info "Created new blog: #{blog.username}"
          else
            Rails.logger.warn "Failed to save blog #{blog_data[:username]}: #{blog.errors.full_messages.join(', ')}"
            @errors << { username: blog_data[:username], error: blog.errors.full_messages.join(', ') }
          end
        else
          # Update existing blog if data has changed
          changes = {}
          changes[:description] = blog_data[:description] if blog.description != blog_data[:description]
          changes[:hyperlink] = blog_data[:hyperlink] if blog.hyperlink != blog_data[:hyperlink]
          
          if changes.any?
            blog.update!(changes)
            Rails.logger.info "Updated blog: #{blog.username}"
          end
          
          @processed_count += 1
        end
      rescue StandardError => e
        Rails.logger.error "Failed to process blog #{blog_data[:username]}: #{e.message}"
        @errors << { username: blog_data[:username], error: e.message }
      end
    end
  end
end
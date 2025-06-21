require 'feedjira'
require 'digest'

class RssFeedParser
  attr_reader :blog, :processed_count, :errors
  
  def initialize(blog)
    @blog = blog
    @processed_count = 0
    @errors = []
  end
  
  def fetch_and_store_posts
    return unless blog.rss_valid?
    
    Rails.logger.info "Fetching RSS feed for #{blog.username}: #{blog.rss}"
    
    begin
      feed = fetch_feed
      return unless feed
      
      process_feed_entries(feed)
      update_blog_last_post_info
      
      Rails.logger.info "RSS processing completed for #{blog.username}. New posts: #{@processed_count}"
      
    rescue StandardError => e
      Rails.logger.error "Failed to process RSS feed for #{blog.username}: #{e.message}"
      @errors << e.message
      raise e
    end
    
    { processed: @processed_count, errors: @errors }
  end
  
  private
  
  def fetch_feed
    response = HTTParty.get(blog.rss, 
      timeout: 30,
      headers: {
        'User-Agent' => 'HN-Blogroll-Bot/1.0 (Feed Reader)',
        'Accept' => 'application/rss+xml, application/xml, text/xml'
      }
    )
    
    unless response.success?
      Rails.logger.warn "Failed to fetch RSS feed for #{blog.username}: HTTP #{response.code}"
      return nil
    end
    
    feed = Feedjira.parse(response.body)
    
    if feed.nil?
      Rails.logger.warn "Failed to parse RSS feed for #{blog.username}"
      return nil
    end
    
    feed
  rescue StandardError => e
    Rails.logger.error "Error fetching RSS feed for #{blog.username}: #{e.message}"
    nil
  end
  
  def process_feed_entries(feed)
    return unless feed.entries
    
    # Sort entries by publication date, newest first
    entries = feed.entries.sort_by(&:published).reverse
    
    entries.each do |entry|
      begin
        process_entry(entry)
      rescue StandardError => e
        Rails.logger.warn "Failed to process entry for #{blog.username}: #{e.message}"
        @errors << "Entry processing error: #{e.message}"
        next
      end
    end
  end
  
  def process_entry(entry)
    return unless entry_valid?(entry)
    
    unique_key = generate_unique_key(entry)
    
    # Skip if we already have this post
    return if Post.exists?(unique_key: unique_key)
    
    post_data = extract_post_data(entry, unique_key)
    
    post = blog.posts.build(post_data)
    
    if post.save
      @processed_count += 1
      Rails.logger.debug "Created post: #{post.title}"
    else
      Rails.logger.warn "Failed to save post for #{blog.username}: #{post.errors.full_messages.join(', ')}"
      @errors << "Post save error: #{post.errors.full_messages.join(', ')}"
    end
  end
  
  def entry_valid?(entry)
    return false unless entry.title.present?
    return false unless entry.url.present?
    return false unless entry.published.present?
    
    # Skip very old posts (more than 2 years old)
    return false if entry.published < 2.years.ago
    
    # Skip posts with suspicious titles
    suspicious_patterns = [
      /^(re:|fwd:)/i,
      /\b(spam|advertisement|ad)\b/i
    ]
    
    !suspicious_patterns.any? { |pattern| entry.title.match?(pattern) }
  end
  
  def generate_unique_key(entry)
    # Create a unique key based on blog, URL, and published date
    key_components = [
      blog.id.to_s,
      entry.url,
      entry.published.to_i.to_s
    ]
    
    Digest::SHA256.hexdigest(key_components.join('|'))
  end
  
  def extract_post_data(entry, unique_key)
    # Extract content, preferring summary over content if it's more reasonable
    content = extract_content(entry)
    
    # Extract author (could be from feed or entry)
    author = extract_author(entry)
    
    # Extract and clean tags
    tags = extract_tags(entry)
    
    {
      title: entry.title.strip,
      url: entry.url,
      content: content,
      published_at: entry.published,
      guid: entry.entry_id,
      unique_key: unique_key,
      author: author,
      tags: tags
    }
  end
  
  def extract_content(entry)
    content = nil
    
    # Try different content fields
    if entry.respond_to?(:content) && entry.content.present?
      content = entry.content
    elsif entry.respond_to?(:summary) && entry.summary.present?
      content = entry.summary
    elsif entry.respond_to?(:description) && entry.description.present?
      content = entry.description
    end
    
    return nil unless content
    
    # Clean HTML and truncate if too long
    cleaned_content = clean_html_content(content)
    
    # Truncate very long content
    cleaned_content.truncate(10000)
  end
  
  def clean_html_content(content)
    # Allow basic HTML tags but remove scripts, styles, etc.
    allowed_tags = %w[p br strong b em i u a ul ol li blockquote h1 h2 h3 h4 h5 h6 code pre]
    allowed_attributes = %w[href title]
    
    ActionController::Base.helpers.sanitize(content, 
      tags: allowed_tags, 
      attributes: allowed_attributes
    )
  end
  
  def extract_author(entry)
    author = nil
    
    if entry.respond_to?(:author) && entry.author.present?
      author = entry.author
    elsif entry.respond_to?(:itunes_author) && entry.itunes_author.present?
      author = entry.itunes_author
    end
    
    # Clean and truncate author name
    if author
      author = ActionController::Base.helpers.sanitize(author, tags: [])
      author = author.strip.truncate(100)
    end
    
    author
  end
  
  def extract_tags(entry)
    tags = []
    
    if entry.respond_to?(:categories) && entry.categories.present?
      tags = entry.categories.map(&:strip).reject(&:blank?)
    elsif entry.respond_to?(:tags) && entry.tags.present?
      tags = entry.tags.map(&:strip).reject(&:blank?)
    end
    
    # Clean and limit tags
    tags = tags.map { |tag| ActionController::Base.helpers.sanitize(tag, tags: []).strip }
    tags = tags.reject(&:blank?).uniq
    tags = tags.first(10) # Limit to 10 tags
    
    tags
  end
  
  def update_blog_last_post_info
    latest_post = blog.posts.recent.first
    return unless latest_post
    
    blog.update!(
      last_post_title: latest_post.title,
      last_post_url: latest_post.url,
      last_post_date: latest_post.published_at&.to_s
    )
  end
end
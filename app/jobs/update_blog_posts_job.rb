class UpdateBlogPostsJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3
  
  def perform(blog_id = nil)
    blogs = blog_id ? [Blog.find(blog_id)] : Blog.approved.with_rss
    
    blogs.each do |blog|
      next unless blog.rss_valid?
      
      begin
        RssFeedParser.new(blog).fetch_and_store_posts
        sleep(1) # Be respectful to RSS feeds
      rescue StandardError => e
        Rails.logger.error "Failed to update posts for blog #{blog.id} (#{blog.username}): #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        next
      end
    end
  end
end
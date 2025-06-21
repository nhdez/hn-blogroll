class UpdateBlogPostsJob < ApplicationJob
  queue_as :default
  
  def perform(blog_id = nil)
    blogs = blog_id ? [Blog.find(blog_id)] : Blog.approved.with_rss
    
    blogs.each do |blog|
      next unless blog.rss_valid?
      
      begin
        RssFeedParser.new(blog).fetch_and_store_posts
        sleep(1) # Be respectful to RSS feeds
      rescue StandardError => e
        logger.error "Failed to update posts for blog #{blog.id} (#{blog.username}): #{e.message}"
        logger.error e.backtrace.join("\n")
        next
      end
    end
  end
end
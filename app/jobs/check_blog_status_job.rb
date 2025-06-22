class CheckBlogStatusJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3
  
  def perform(blog_id = nil)
    blogs = blog_id ? [Blog.find(blog_id)] : Blog.approved
    
    blogs.each do |blog|
      begin
        BlogStatusChecker.new(blog).check_and_update_status
        sleep(0.5) # Be respectful when checking URLs
      rescue StandardError => e
        Rails.logger.error "Failed to check status for blog #{blog.id} (#{blog.username}): #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        next
      end
    end
  end
end
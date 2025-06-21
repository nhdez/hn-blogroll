class UpdateKarmaJob < ApplicationJob
  queue_as :default
  
  def perform(blog_id = nil)
    blogs = blog_id ? [Blog.find(blog_id)] : Blog.approved
    
    blogs.each do |blog|
      begin
        KarmaUpdater.new(blog).update_karma
        sleep(0.5) # Be respectful to HN API
      rescue StandardError => e
        logger.error "Failed to update karma for blog #{blog.id} (#{blog.username}): #{e.message}"
        logger.error e.backtrace.join("\n")
        next
      end
    end
  end
end
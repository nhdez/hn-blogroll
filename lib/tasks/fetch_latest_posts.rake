namespace :blogroll do
  desc "Fetch latest posts from all blog RSS feeds"
  task :update_posts => :environment do
    puts "Queueing job to update blog posts..."
    UpdateBlogPostsJob.perform_async
    puts "Job queued successfully"
  end

  desc "Fetch latest posts from specific blog"
  task :update_blog_posts, [:blog_id] => :environment do |task, args|
    blog_id = args[:blog_id]
    if blog_id.blank?
      puts "Usage: rake blogroll:update_blog_posts[blog_id]"
      exit 1
    end
    
    puts "Queueing job to update posts for blog #{blog_id}..."
    UpdateBlogPostsJob.perform_async(blog_id)
    puts "Job queued successfully"
  end

  desc "Fetch new blogs from HackerNews thread"
  task :fetch_hn_data => :environment do
    puts "Queueing job to fetch HN data..."
    FetchHnDataJob.perform_async
    puts "Job queued successfully"
  end

  desc "Update karma for all blogs"
  task :update_karma => :environment do
    puts "Queueing job to update karma..."
    UpdateKarmaJob.perform_async
    puts "Job queued successfully"
  end

  desc "Check blog status for all blogs"
  task :check_status => :environment do
    puts "Queueing job to check blog status..."
    CheckBlogStatusJob.perform_async
    puts "Job queued successfully"
  end

  desc "Run all maintenance tasks"
  task :full_update => :environment do
    puts "Running full blogroll update..."
    FetchHnDataJob.perform_async
    UpdateBlogPostsJob.perform_async
    UpdateKarmaJob.perform_async
    CheckBlogStatusJob.perform_async
    puts "All jobs queued successfully"
  end
end

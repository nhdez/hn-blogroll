namespace :fetch_latest_posts do
  desc "Refetch the blog posts"
  task initialize: :environment do
    refresh_data = FetchLatestPostsService.new
    refresh_data.call
  end
end

namespace :update_online_status do
  desc "Refetch the OPML data for each blog"
  task initialize: :environment do
    refresh_data = UpdateOnlineStatusService.new
    refresh_data.call
  end
end

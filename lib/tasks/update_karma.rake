namespace :update_karma do
  desc "Update each users karma count"
  task initialize: :environment do
    refresh_data = UpdateKarmaService.new
    refresh_data.call
  end
end

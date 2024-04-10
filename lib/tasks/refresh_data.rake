namespace :refresh_data do
  desc "Refetch the Blog List from HN"
  task initialize: :environment do
    refresh_data = RefreshDataService.new
    refresh_data.call
  end
end

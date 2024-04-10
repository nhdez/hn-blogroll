namespace :fetch_opml_data do
  desc "Refetch the OPML data for each blog"
  task initialize: :environment do
    refresh_data = FetchOpmlDataService.new
    refresh_data.call
  end
end

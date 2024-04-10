set :environment, "development"
every 1.minute do
  runner "RefreshDataJob.perform_now"
end

set :environment, "production"
every 3.hours do
  runner "RefreshDataJob.perform_now"
end

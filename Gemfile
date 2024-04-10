source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.1"
gem "rails", "~> 7.0.5"
gem "pg", "~> 1.5"
gem "sprockets-rails"
gem "puma", "~> 5.0"
gem "feedjira"
gem "kaminari"
gem "ransack"
gem "icodi"
gem "opml-parser"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "better_errors"
  gem "binding_of_caller"
  gem "dotenv-rails"
end

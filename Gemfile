source "https://rubygems.org"

gemspec

group :development, :test, :production do
  gem "jquery-rails"
  gem "quiet_assets"
  gem "rails", ">= 3.0.10"
  gem "slim"
  gem "sqlite3"
end

group :test do
  gem "rspec-rails", "2.14.0"
end

group :development, :test do
  gem "pry-rails"
  gem "thin"
end

group :assets do
  gem "sass-rails", ">= 3.0.10"
  gem "coffee-rails", ">= 3.0.10"
  gem "uglifier"
end

source "https://rubygems.org"

gemspec

group :development, :test, :production do
  gem "jquery-rails"
  gem "quiet_assets"
  gem "rails", ">= 4.0.0"
  gem "slim"
  gem "sqlite3"
end

group :test do
  gem "rspec-rails", "~> 2.99.0"
end

group :development, :test do
  gem "pry-rails"
  gem "thin"
end

group :assets do
  gem "sass-rails"
  gem "coffee-rails"
  gem "uglifier"
end

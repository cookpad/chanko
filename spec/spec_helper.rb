# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
#require File.expand_path("../../config/environment", __FILE__)
if RUBY_VERSION =~ /\A1.9.*/
  require 'simplecov'
  SimpleCov.start do
    coverage_dir '/tmp/cov'
  end
end

require 'chanko'
require 'app'
require 'rspec/rails'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require File.expand_path(f)}

#move to support
def fixtures_path
  Pathname.new(File.expand_path('fixtures', File.dirname(__FILE__)))
end

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #config.use_transactional_fixtures = true

  config.before(:suite) do
    $: << fixtures_path.join('lib')
    path = fixtures_path.join('test_extensions')
    Chanko::Loader.directories.unshift(path)
    Chanko::ActiveIf.files = [fixtures_path.join('active_if', "main")]
    ApplicationController.send(:include, Chanko::Invoker)
    ActionView::Base.send(:include, Chanko::Invoker)
    CreateAllTables.up unless ActiveRecord::Base.connection.table_exists? 'users'
  end
  config.before do
    Chanko::Helper.stub!(:check_to_update_interval).and_return(0)
  end

  config.after do
    Chanko::Loader.clear_cache!
    Chanko::Helper.reset
  end
end


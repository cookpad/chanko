require 'simplecov'

SimpleCov.start 'rails' do
  if ENV['CI']
    require 'simplecov-lcov'
    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end
    formatter SimpleCov::Formatter::LcovFormatter
  end

  add_filter "/spec\/dummy/"
end

ENV["RAILS_ENV"] ||= "test"
require "chanko"
require "chanko/test"
Chanko::Config.units_directory_path = File.expand_path("../fixtures/units", __FILE__)

require File.expand_path("../dummy/config/environment", __FILE__)
require "rspec/rails"


RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.after do
    Chanko::Config.reset
    Chanko::Config.units_directory_path = File.expand_path("../fixtures/units", __FILE__)
  end

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!

  if Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
    config.filter_run_excluding classic: true
  else
    config.filter_run_excluding zeitwerk: true
  end
end


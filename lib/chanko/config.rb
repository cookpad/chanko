module Chanko
  def self.configure(&block)
    yield @config ||= Configuration.new
  end

  def self.config
    @config
  end

  class Configuration
    include ActiveSupport::Configurable

    config_accessor :raise
    config_accessor :test
    config_accessor :cache_classes
    config_accessor :default_active_if
    config_accessor :default_view_type
    config_accessor :view_resolver
  end

  configure do |config|
    config.raise = false
    config.test = Rails.env.test?
    config.cache_classes = Rails.application.config.cache_classes
    config.default_active_if = lambda { false }
    config.default_view_type = :block
    config.view_resolver = nil
  end
end



module Chanko
  class ExceptionNotifier
    include ActiveSupport::Callbacks
    define_callbacks :notify
    attr_accessor :message, :payload, :force

    def self.notify(message, force, payload={})
      self.new(message, force, payload).notify
    end

    def initialize(message, force, payload)
      self.message = message
      self.force = force
      self.payload = payload
    end

    def notify
      run_callbacks :notify do
        backtrace = payload[:exception].try(:backtrace).try(:[], 0..10).try(:join, "\n")
        Rails.logger.debug("Chanko::Exception #{message}\n#{backtrace}")
      end

      raise payload[:exception] if Chanko.config.exceptions_to_pass_through.include?(payload[:exception].class)
      raise payload[:exception_klass] if Chanko.config.exceptions_to_pass_through.include?(payload[:exception_klass])

      return if !force && !Chanko.config.raise
      raise payload[:exception] if payload[:exception]
      raise payload[:exception_klass], message if payload[:exception_klass]
      raise Chanko::Exception, message
    end
  end
end

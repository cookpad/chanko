module Chanko
  class ExceptionNotifier
    include Chanko::Callbacks
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
        Rails.logger.debug("Chanko::Exception #{message} #{payload.inspect}")
      end
      return if !force && !Chanko.config.raise
      raise payload[:exception] if payload[:exception]
      raise payload[:exception_klass], message if payload[:exception_klass]
      raise Chanko::Exception, message
    end
  end
end

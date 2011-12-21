module Chanko
  module Log
    mattr_accessor :limited_logs
    self.limited_logs = {}
    LIMIT = 3

    def self.url(context)
      #Don't use .try(:xxx). Some objects don't work well
      return nil unless context.respond_to?(:controller)
      return nil unless context.controller.respond_to?(:request)
      return nil unless context.controller.request.respond_to?(:url)
      context.controller.request.url
    end

    def self.log(*args)
      return unless defined?(::ErrorLog)
      options = args.extract_options!
      message = args
      options[:key] ||= message
      backtrace = options[:backtrace]
      self.limited_logs[options[:key]] ||= 0
      return if self.limited_logs[options[:key]] >= LIMIT
      self.limited_logs[options[:key]] += 1

      backtrace = backtrace.join("\n") if backtrace.is_a?(Array)
      #Create raise error if Time now was overrided. so should rescue.
      if Time.respond_to?(:origina_time_scope)
        Time.original_time_scope do
          ::ErrorLog.create(:errortype => 'extension', :message => message, :stack_trace => backtrace, :url => self.url(options[:context]))
        end
      else
        ::ErrorLog.create(:errortype => 'extension', :message => message, :stack_trace => backtrace, :url => self.url(options[:context]))
      end
    end
  end
end

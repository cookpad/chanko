module Chanko
  class ExceptionHandler
    def self.handle(*args)
      new(*args).handle
    end

    attr_reader :exception, :unit

    def initialize(exception, unit = nil)
      @exception = exception
      @unit      = unit
    end

    def handle
      if propagated?
        raise exception
      else
        log
        raise exception if raised?
      end
    end

    private

    def propagated?
      Config.propagated_errors.any? {|klass| exception.is_a?(klass) }
    end

    def raised?
      unit.try(:raise_error?) || Config.raise_error
    end

    def log
      Logger.debug(exception)
    end
  end
end

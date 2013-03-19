module Chanko
  module ExceptionHandler
    class << self
      def handle(exception, unit = nil)
        Logger.debug(exception)
        raise exception if unit.try(:raise_error?) || Config.raise_error
      end
    end
  end
end

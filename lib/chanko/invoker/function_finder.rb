module Chanko
  module Invoker
    class FunctionFinder
      def self.find(context, options)
        new(context, options).find
      end

      attr_reader :context, :options

      delegate :active_if_options, :as, :label, :unit_name, :to => :options

      def initialize(context, options)
        @context = context
        @options = options
      end

      def find
        active? && find_function
      end

      def scope
        as || context.class
      end

      def unit
        Loader.load(unit_name)
      end

      def find_function
        unit.find_function(scope, label)
      end

      def active?
        if unit
          unit.active?(context, active_if_options)
        else
          false
        end
      end
    end
  end
end

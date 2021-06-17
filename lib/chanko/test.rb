module Chanko
  module Test
    class << self
      def activations
        @activations ||= {}
      end

      def included(base)
        base.send :include, UnitProxyProvider
      end
    end

    def enable_unit(unit_name)
      Test.activations[unit_name] = true
    end
    alias_method :enable_ext, :enable_unit

    def disable_unit(unit_name)
      Test.activations[unit_name] = false
    end
    alias_method :disable_ext, :disable_unit
  end

  module Unit
    module ClassMethods
      def active_with_activations?(*args)
        case Test.activations[unit_name]
        when true
          true
        when false
          false
        else
          active_without_activations?(*args)
        end
      end
      alias_method :active_without_activations?, :active?
      alias_method :active?, :active_with_activations?
    end
  end
end

RSpec.configure do |config|
  config.include Chanko::Test
  config.after { Chanko::Test.activations.clear }
end

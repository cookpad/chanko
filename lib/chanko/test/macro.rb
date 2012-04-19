module Chanko
  module Test
    module Macro
      def enable_unit(*args)
        options = args.extract_options!
        unit, user_id = args[0..1]
        Chanko::Test::Mock.enable(unit, user_id, options)
      end
      alias_method :enable_ext, :enable_unit
      alias_method :active_ext, :enable_ext

      def disable_unit(*args)
        options = args.extract_options!
        unit, user_id = args[0..1]
        Chanko::Test::Mock.disable(unit, user_id, options)
      end
      alias_method :disable_ext, :disable_unit
      alias_method :deactive_ext, :disable_ext

      def raise_chanko_exception
        Chanko.config.raise = true
      end

      def no_raise_chanko_exception
        Chanko.config.raise = false
      end
    end
  end
end

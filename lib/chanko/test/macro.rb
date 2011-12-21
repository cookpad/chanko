module Chanko
  module Test
    module Macro
      def enable_ext(*args)
        options = args.extract_options!
        ext, user_id = args[0..1]
        Chanko::Test::Mock.enable(ext, user_id, options)
      end
      alias_method :active_ext, :enable_ext

      def disable_ext(*args)
        options = args.extract_options!
        ext, user_id = args[0..1]
        Chanko::Test::Mock.disable(ext, user_id, options)
      end
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

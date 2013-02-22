module Chanko
  module Invoker
    class Options
      CANDIDATES = {
        :active_if_options => true,
        :as                => true,
        :capture           => true,
        :locals            => true,
        :type              => true,
      }

      def initialize(*args)
        @raw_options = args.extract_options!
        @args = args
      end

      def unit_name
        @args[0]
      end

      def label
        @args[1]
      end

      def locals
        (options[:locals] || {}).symbolize_keys
      end

      def active_if_options
        options[:active_if_options] || {}
      end

      def as
        options[:as]
      end

      def capture
        options.has_key?(:capture) ? capture[:capture] : true
      end

      def type
        options[:type]
      end

      def invoke_options
        { :capture => capture, :type => type }
      end

      def options
        @options ||= begin
          if short_hand_options?
            { :locals => @raw_options }
          else
            @raw_options
          end
        end
      end

      def short_hand_options?
        @raw_options.any? && @raw_options.keys.all? {|key| !CANDIDATES[key] }
      end
    end
  end
end

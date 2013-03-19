module Chanko
  module Unit
    class ScopeFinder
      LABEL_SCOPE_MAP = {
        :controller => ActionController::Base,
        :model      => ActiveRecord::Base,
        :view       => ActionView::Base,
      }

      def self.find(*args)
        new(*args).find
      end

      def initialize(identifier)
        @identifier = identifier
      end

      def find
        case
        when class?
          @identifier
        when label
          label
        else
          @identifier.to_s.constantize
        end
      rescue NameError
      end

      private

      def class?
        @identifier.is_a?(Class)
      end

      def label
        LABEL_SCOPE_MAP[@identifier]
      end
    end
  end
end

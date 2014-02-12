module Chanko
  module Unit
    class ScopeFinder
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
        label_scope_map = {
          :controller => ActionController::Base,
          :model      => ActiveRecord::Base,
          :view       => ActionView::Base
        }

        label_scope_map[@identifier]
      end
    end
  end
end

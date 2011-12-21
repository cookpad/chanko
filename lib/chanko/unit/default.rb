module Chanko
  module Unit
    module Default
      include Chanko::Unit
      self.default = true

      def self.stylesheet_name
        ''
      end
    end
  end
end

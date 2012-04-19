module Chanko
  module Unit
    module Default
      include Chanko::Unit
      self.default = true

      def self.css_name
        ''
      end
    end
  end
end

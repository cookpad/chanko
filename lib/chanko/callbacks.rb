module Chanko
  module Callbacks
    def self.included(obj)
      obj.class_eval do
        include ActiveSupport::Callbacks
      end
    end
  end
end

#TODO test
module Chanko
  module Controller
    def self.included(obj)
      obj.class_eval do
        include Chanko::Invoker
        include Chanko::MethodProxy
        extend Chanko::Controller::ClassMethods
      end
    end

    module ClassMethods
      def ext_action(ext_name, callback_name, options={}, &block)
        action_name = options.delete(:action) || callback_name
        block ||= Proc.new { head(400) }

        define_method(action_name) do
          invoke(ext_name, callback_name, options, &block)
        end
      end
    end
  end
end

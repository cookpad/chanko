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
      def unit_action(unit_name, function_name, options={}, &block)
        action_name = options.delete(:action) || function_name
        block ||= Proc.new { head(400) }

        define_method(action_name) do
          invoke(unit_name, function_name, options, &block)
        end
      end
      alias_method :ext_action, :unit_action
    end
  end
end

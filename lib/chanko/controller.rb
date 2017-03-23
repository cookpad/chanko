module Chanko
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      private

      def inherited(base)
        if Config.auto_reload && base.name == "ApplicationController"
          base.class_eval do
            prepend_before_action do
              Chanko::Loader.cache.clear
            end
          end
        end
        super
      end

      def unit_action(unit_name, *function_names, &block)
        options = function_names.extract_options!
        block ||= Proc.new { head 400 }
        Array.wrap(function_names).each do |function_name|
          define_method(function_name) do
            invoke(unit_name, function_name, options, &block)
          end
        end
      end
      alias_method :ext_action, :unit_action
    end
  end
end

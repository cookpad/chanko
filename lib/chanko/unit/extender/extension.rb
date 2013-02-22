module Chanko
  module Unit
    class Extender
      class Extension < Module
        include ActiveRecordClassMethods

        def initialize(mod, prefix = nil, &block)
          @mod    = mod
          @prefix = prefix
          @block  = block
          define_methods_with_prefix(instance_methods_module, &block)
        end

        def class_methods(&block)
          define_methods_with_prefix(class_methods_module, &block)
        end

        def instance_methods_module
          self
        end

        def class_methods_module
          @class_methods_module ||= Module.new
        end

        private

        def define_methods_with_prefix(container, &block)
          define_methods(container, &block).each do |added_method_name|
            change_method_name_with_prefix(container, added_method_name) if @prefix.present?
          end
        end

        def define_methods(container, &block)
          before = container.instance_methods(false)
          container.class_eval(&block)
          container.instance_methods(false) - before
        end

        def change_method_name_with_prefix(container, method_name)
          from = method_name
          to   = "#@prefix#{method_name}"
          container.class_eval do
            alias_method to, from
            remove_method from
          end
        end
      end
    end
  end
end

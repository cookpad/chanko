module Chanko
  module Helper
    class << self
      def define(unit_name, &block)
        prefix = UnitProxy.generate_prefix(unit_name)
        define_methods_with_prefix(prefix, &block)
      end

      def define_methods_with_prefix(prefix, &block)
        define_methods(&block).each do |name|
          change_method_name(name, "#{prefix}#{name}")
        end
      end

      def define_methods(&block)
        before = instance_methods(false)
        self.class_eval(&block)
        instance_methods(false) - before
      end

      def change_method_name(from, to)
        class_eval do
          alias_method to, from
          remove_method from
        end
      end
    end
  end
end

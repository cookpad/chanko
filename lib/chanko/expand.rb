module Chanko
  module Expand
    def self.included(obj)
      obj.extend(ExpandClassMethods)
      obj.class_eval do
        mattr_accessor :prefix
        def self.included(include_obj)
          if self.constants.map(&:to_s).include?("ClassMethods")
            cmethods = self.const_get("ClassMethods")
            include_obj.extend(cmethods)
          end
        end
      end
    end

    module ExpandClassMethods
      extend ActiveSupport::Memoizable
      def class_methods(&block)
        class_eval do
          unless constants.map(&:to_s).include?("ClassMethods")
            self.const_set("ClassMethods", Module.new)
            cmethods = self.const_get("ClassMethods")
          end
          cmethods ||= self.const_get("ClassMethods")
          cmethods.class_eval(&block)
        end
      end
      private :class_methods

      def attach(target)
        @klass = target
        expand!
        target.send(:include, self)
        run_after_callbacks(target)
      end

      def expanded_already?(method)
        !!(method =~ /^#{prefix}/)
      end
      private :expanded_already?

      def prefix_method(method)
       "#{prefix}#{method}".to_sym
      end
      private :prefix_method
      alias_method :label ,:prefix_method

      def self_methods
        ['prefix', 'prefix=']
      end
      memoize :self_methods


      def expand(obj)
        obj.instance_methods(false).each do |method|
          next if expanded_already?(method)
          next if self_methods.include?(method)
          new_method = prefix_method(method)
          obj.class_eval do
            alias_method new_method, method
            remove_method(method)
          end
        end
      end
      private :expand

      def expand!
        return false if @expanded
        expand(self)
        if self.constants.map(&:to_s).include?("ClassMethods")
          cmethods = self.const_get("ClassMethods")
          expand(cmethods)
        end

        @expanded = true
        return true
      end

      def expanded?
        !!@expanded
      end

      def add_after_callback(&block)
        @after_callbacks ||= []
        @after_callbacks << block
      end
      private :add_after_callback

      def run_after_callbacks(target)
        @after_callbacks ||= []
        @after_callbacks.each do |callback|
          callback.call(target, prefix)
        end
      end
      private :run_after_callbacks

      #TODO remove
      def expanded=(bool)
        @expaned = bool
      end
    end
  end
end





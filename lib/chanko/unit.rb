require "chanko/unit/extender"
require "chanko/unit/scope_finder"

module Chanko
  module Unit
    extend ActiveSupport::Concern

    included do
      active_if { true }
    end

    module ClassMethods
      attr_accessor :current_scope

      def scope(identifier)
        self.current_scope = ScopeFinder.find(identifier)
        scopes[current_scope] ||= {}
        yield
      ensure
        self.current_scope = nil
      end

      def function(label, &block)
        functions[label] = Function.new(self, label, &block)
      end
      alias_method :callback, :function

      def shared(label, &block)
        shared_methods[label] = block
      end

      def helpers(&block)
        Helper.define(unit_name, &block)
      end

      def models(&block)
        extender.instance_eval(&block)
      end

      def active_if(*conditions, &block)
        @active_if = ActiveIf.new(*conditions, &block)
      end

      def active?(context, options = {})
        @active_if.active?(context, options.merge(:unit => self))
      end

      def any(*labels)
        ActiveIf::Any.new(*labels)
      end

      def raise_error
        @raise_error = true
      end
      alias_method :propagates_errors, :raise_error

      def raise_error?
        @raise_error
      end

      def unit_name
        @unit_name ||= name.underscore.to_sym
      end

      def to_prefix
        UnitProxy.generate_prefix(unit_name)
      end

      def view_path
        "#{Config.units_directory_path}/#{unit_name}/views"
      end

      def find_function(identifier, label)
        scope     = ScopeFinder.find(identifier)
        target    = scope.ancestors.find {|klass| scopes[klass] }
        functions = scopes[target]
        functions[label] if functions
      end

      def functions
        scopes[current_scope]
      end

      def scopes
        @scopes ||= {}
      end

      def shared_methods
        @shared_methods ||= {}
      end

      def resolver
        @resolver ||= Config.resolver.new(view_path)
      end

      def extender
        @extender ||= Extender.new(to_prefix)
      end
    end
  end
end

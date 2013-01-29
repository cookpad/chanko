module Chanko
  module Invoker
    def self.included(obj)
      obj.class_eval do
        include InstanceMethods

        mattr_accessor :defined_blocks
        attr_accessor :attached_unit_classes
        attr_accessor :__current_function
      end

    end

    def method_missing(method_symbol, *args)
      if block = self.attached_unit_classes.try(:last).try(:shared_method, method_symbol)
        self.instance_exec(*args, &block)
      else
        super(method_symbol, *args)
      end
    end

    module InstanceMethods
      def view?
        self.is_a?(ActionView::Base) && respond_to?("concat")
      end

      def method_missing(method_symbol, *args)
        if _has_local_val?(method_symbol, *args)
          return _local_val(method_symbol)
        end
        super(method_symbol, *args)
      end

      def _local_val(method_symbol)
        current_locals[method_symbol]
      end
      private :_local_val

      def unit_locals
        @__unit_locals ||= []
      end
      private :unit_locals

      def current_locals
        unit_locals.last || {}
      end
      private :current_locals

      def _has_local_val?(method_symbol, *args)
        return false unless current_locals
        return false unless current_locals.key?(method_symbol)
        return false unless args.blank?
        return true
      end
      private :_has_local_val?

      INVOKE_OPTIONS = [:locals, :active_if_options, :capture, :if, :type, :as].freeze

      def invoke(*args, &block)
        options = args.extract_options!
        unit_name = args[0]
        function_name = args[1]

        if options.present? && !options.keys.any? { |option| INVOKE_OPTIONS.include?(option) }
          locals = options
          options = {}
          options[:locals] = locals
        end

        options.reverse_merge!(:locals => {}, :active_if_options => {}, :capture => true)
        active_if_options = options.delete(:active_if_options)
        depend_on = options.delete(:if)
        unit_locals.push(options.delete(:locals).symbolize_keys)

        Chanko::Loader.requested(unit_name)
        unit_function = function(unit_name, function_name, depend_on, active_if_options, options)

        if default = Chanko::Function.default(&block)
          default.called_from = args.join("#")
        end

        return nil if unit_function.blank? && !default
        render_function(unit_function, default, options)
      ensure
        unit_locals.pop
      end


      def validate_depend_on_units(depended_units, options={})
        return true unless depended_units
        Array.wrap(depended_units).each do |unit_name|
          return false unless unit = Chanko::Loader.fetch(unit_name)
          return false unless unit.enabled?(self, options)
        end
        return true
      end
      private :validate_depend_on_units

      def aborted?(unit)
        Chanko::Loader.aborted_units.include?(unit.unit_name)
      end
      private :aborted?

      def function(unit_name, function_name, depend_on, active_if_options, options={})
        return nil unless validate_depend_on_units(depend_on, active_if_options)
        return nil unless unit = Chanko::Loader.fetch(unit_name)
        return nil if aborted?(unit)
        unit_function = unit.fetch_function(self, function_name, active_if_options, options)
        return nil if unit_function.blank?
        Chanko::Loader.invoked(unit_name)
        return unit_function
      end
      private :function

      def run_function(function, options)
        if function.unit.default?
          mes = "[DEFAULT CALLBACK] <- #{function.called_from}"
        else
          mes = "#{function.unit.name}##{function.label}"
        end
        Rails.logger.debug("Chanko::Run \e[0;32mcall\e[0m #{mes}")
        result = function.invoke!(self, options)
        return str_or_nil(result) unless Chanko::Aborted == result
        raise Chanko::Aborted
      end
      private :run_function

      def render_function(function, default, options)
        begin
          @__unit_default ||= []
          @__unit_default.unshift(default)
          begin
            if function
              result = run_function(function, options)
              return result || ''
            end
          rescue Chanko::Aborted
          end
          return '' unless default
          return run_function(default, options.merge(:raise_exception => true))
        ensure 
          @__unit_default.shift
        end
      end

      def run_default
        default = @__unit_default[0]
        return nil unless default
        result = run_function(default, {:type => :plain, :capture => view?, :raise_exception => true})
      end

      def str_or_nil(str)
        str.is_a?(String) ? str : nil
      end
      private :str_or_nil
    end
  end
end

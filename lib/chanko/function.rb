module Chanko
  class Function
    attr_reader :block, :unit, :label

    THREAD_LOCAL_UNITS_KEY = :chanko_units

    class << self
      def units
        Thread.current[THREAD_LOCAL_UNITS_KEY] ||= []
      end

      def current_unit
        units.last
      end
    end

    def initialize(unit, label, &block)
      @unit  = unit
      @label = label
      @block = block
    end

    def invoke(context, options = {})
      with_unit_stack(context) do
        with_unit_view_path(context) do
          capture_exception(context) do
            result = context.instance_eval(&block)
            result = decorate(result, context, options[:type]) if context.view? && result.present?
            result
          end
        end
      end
    end

    def css_classes
      if Config.compatible_css_class
        %W[
          extension
          ext_#{unit.unit_name}
          ext_#{unit.unit_name}-#{label}
        ]
      else
        %W[
          unit
          unit__#{unit.unit_name}
          unit__#{unit.unit_name}__#{label}
        ]
      end
    end

    private

    def with_unit_stack(context)
      context.units << @unit
      self.class.units << @unit
      yield
    ensure
      self.class.units.pop
      context.units.pop
    end

    def with_unit_view_path(context)
      context.view_paths.unshift unit.resolver if context.respond_to?(:view_paths)
      yield
    ensure
      context.view_paths.paths.shift if context.respond_to?(:view_paths)
    end

    def capture_exception(context)
      yield
    rescue Exception => exception
      ExceptionHandler.handle(exception, unit)
      context.run_default
    end

    def decorate(str, context, type)
      case type
      when :plain
        str
      when :inline
        context.content_tag(:span, str, :class => css_classes)
      else
        context.content_tag(:div, str, :class => css_classes)
      end
    end
  end
end

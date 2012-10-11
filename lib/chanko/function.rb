module Chanko
  class Function
    include ActiveSupport::Callbacks
    define_callbacks :invoke

    autoload :ActionView, 'action_view'

    class TagHelper
      include ActionView::Helpers::TagHelper
    end

    attr_reader :label, :block, :options, :unit
    attr_accessor :called_from # for debug
    attr_accessor :__current_scope

    def self.default(&block)
      return nil unless block_given?
      Chanko::Function.new(:__default__, Chanko::Unit::Default, &block)
    end

    def initialize(label, unit, options={}, &block)
      @label = label.to_s.to_sym if label
      @block = block
      @unit = unit
      @options = options
    end

    def tag_helper
      @tag_helper ||= TagHelper.new
    end

    def invoke!(scope, options={})
      begin
        self.__current_scope = scope
        scope.__current_function = self
        run_callbacks :invoke do
          Chanko::Loader.push_scope(unit.underscore)
          result = nil
          self.unit.attach(scope) do
            if self.unit.default? && scope.view? && options[:capture]
              if scope.respond_to?("capture_haml") && scope.is_haml? && scope.block_is_haml?(block)
                result = scope.capture_haml(&block)
              else
                result = scope.capture(&block)
              end
            else
              result = scope.instance_eval(&block)
            end
            result = result.first if result.kind_of?(Array)
            if scope.view? && !result.blank?
              result = view_result(result, options[:type])
            end
          end
          result
        end
      rescue ::Exception => e
        Chanko::Loader.aborted(unit.unit_name)
        Chanko::ExceptionNotifier.notify("raise exception #{unit.name}##{@label} => #{e.message}", @unit.propagates_errors?,
                                :exception => e, :backtrace =>  e.backtrace[0..20], :key => "#{unit.name}_exception", :context => scope)
        return Chanko::Aborted
      ensure
        Chanko::Loader.pop_scope
        self.__current_scope = nil
        scope.__current_function = nil
      end
    end

    def view_result(result, type)
      return result if self.unit.default?
      case type
      when :plain
        result
      when :inline
        tag_helper.content_tag(:span, result, :class => unit_class)
      when :block
        tag_helper.content_tag(:div, result, :class => unit_class)
      else
        view_result(result, Chanko.config.default_view_type)
      end
    end

    def unit_class
      if Chanko.config.compatible_css_class
        "extension ext_#{self.unit.css_name} ext_#{self.unit.css_name}-#{label.to_s}"
      else
        css_class = Chanko.config.css_class
        "#{css_class} #{css_class}__#{self.unit.css_name} #{css_class}__#{self.unit.css_name}__#{label.to_s}"
      end
    end
  end
end

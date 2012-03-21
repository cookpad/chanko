module Chanko
  class Callback
    include Chanko::Callbacks
    define_callbacks :invoke

    autoload :ActionView, 'action_view'

    class TagHelper
      include ActionView::Helpers::TagHelper
    end

    attr_reader :label, :block, :options, :ext
    attr_accessor :called_from # for debug
    attr_accessor :__current_scope

    def self.default(&block)
      return nil unless block_given?
      Chanko::Callback.new(:__default__, Chanko::Unit::Default, &block)
    end

    def initialize(label, ext, options={}, &block)
      @label = label.to_s.to_sym if label
      @block = block
      @ext = ext
      @options = options
    end

    def tag_helper
      @tag_helper ||= TagHelper.new
    end

    def invoke!(scope, options={})
      begin
        self.__current_scope = scope
        scope.__current_callback = self
        run_callbacks :invoke do
          Chanko::Loader.push_scope(ext.underscore)
          result = nil
          self.ext.attach(scope) do
            if self.ext.default? && scope.view? && options[:capture]
              result = scope.capture(&block)
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
        Chanko::ExceptionNotifier.notify("raise exception #{ext.name}##{@label} => #{e.message}", self.ext.default?,
                                :exception => e, :backtrace =>  e.backtrace[0..20], :key => "#{ext.name}_exception", :context => scope)
        return Chanko::Aborted
      ensure
        Chanko::Loader.pop_scope
        self.__current_scope = nil
        scope.__current_callback = nil
      end
    end

    def view_result(result, type)
      case type
      when :plain
        result
      when :inline
        tag_helper.content_tag(:span, result, :class => chanko_class)
      when :block
        tag_helper.content_tag(:div, result, :class => chanko_class)
      else
        view_result(result, Chanko.config.default_view_type)
      end
    end

    def chanko_class
      "extension ext_#{self.ext.stylesheet_name} ext_#{self.ext.stylesheet_name}-#{label.to_s}"
    end
  end
end

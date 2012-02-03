module Chanko
  module Invoker
    def self.included(obj)
      obj.class_eval do
        include InstanceMethods
        extend ClassMethods

        mattr_accessor :defined_blocks
        attr_accessor :attached_extension_classes
        attr_accessor :__current_callback

        define_once(:method_missing_with_shared_method) do
          def method_missing_with_shared_method(method_symbol, *args)
            if block = self.attached_extension_classes.try(:last).try(:shared_method, method_symbol)
              self.instance_exec(*args, &block)
            else
              method_missing_without_shared_method(method_symbol, *args)
            end
          end
          alias_method_chain :method_missing, :shared_method
        end
      end
    end

    module ClassMethods
      def define_once(name)
        return if self.instance_methods.map(&:to_s).include?(name.to_s)
        yield
      end
    end

    module InstanceMethods
      def view?
        self.is_a?(ActionView::Base) && respond_to?("concat")
      end

      def method_missing_with_access_locals(method_symbol, *args)
        if _has_local_val?(method_symbol, *args)
          return _local_val(method_symbol)
        end
        method_missing_without_access_locals(method_symbol, *args)
      end
      alias_method_chain :method_missing, :access_locals

      def _local_val(method_symbol)
        current_locals[method_symbol]
      end
      private :_local_val

      def extension_locals
        @__extension_locals ||= []
      end
      private :extension_locals

      def current_locals
        extension_locals.last || {}
      end
      private :current_locals

      def _has_local_val?(method_symbol, *args)
        return false unless current_locals
        return false unless current_locals.key?(method_symbol)
        return false unless args.blank?
        return true
      end
      private :_has_local_val?

      def requests(_requests)
        return _requests if _requests.first.is_a?(Array)
        return [[_requests[0], _requests[1]]] #[[ext_name, label]]
      end
      private :requests

      def extension_names(requests)
        return requests.transpose.first if requests.first.is_a?(Array)
        return [requests[0]]
      end
      private :extension_names

      def invoke(*args, &block)
        options = args.extract_options!
        options.reverse_merge!(:locals => {}, :active_if_options => {}, :capture => true)
        active_if_options = options.delete(:active_if_options)
        depend_on = options.delete(:if)
        extension_locals.push(options.delete(:locals).symbolize_keys)

        Chanko::Loader.requested(extension_names(args))
        callbacks = get_callbacks(requests(args), depend_on, active_if_options, options)
        if default = Chanko::Callback.default(&block)
          default.called_from = args.join("#")
        end
        return nil if callbacks.blank? && !default
        render_callbacks(callbacks, default, options)
      ensure
        @__ext_default = nil
        extension_locals.pop
      end

      def array(obj)
        obj.is_a?(Array) ? obj : [obj]
      end
      private :array

      def validate_depend_on_extensions(depended_extensions, options={})
        return true unless depended_extensions
        array(depended_extensions).each do |ext_name|
          return false unless ext = Chanko::Loader.fetch(ext_name)
          return false unless ext.enabled?(self, options)
        end
        return true
      end
      private :validate_depend_on_extensions

      def get_callbacks(requests, depend_on, active_if_options, options={})
        return [] unless validate_depend_on_extensions(depend_on, active_if_options)
        requests.each do |extension_name, label|
          next unless ext = Chanko::Loader.fetch(extension_name)
          callbacks = ext.callbacks(self, label, active_if_options, options)
          next if callbacks.blank?
          Chanko::Loader.invoked(extension_name)
          return callbacks
        end
        []
      end
      private :get_callbacks

      def run_callback(callback, options)
        if callback.ext.default?
          mes = "[DEFAULT CALLBACK] <- #{callback.called_from}"
        else
          mes = "#{callback.ext.name}##{callback.label}"
        end
        Rails.logger.debug("Chanko::Run \e[0;32mcall\e[0m #{mes}")
        result = callback.invoke!(self, options)
        return str_or_nil(result) unless Chanko::Aborted == result
        return Chanko::Aborted
      end
      private :run_callback

      def render_callbacks(callbacks, default, options)
        buffer = ActiveSupport::SafeBuffer.new
        succeeded_callbacks = []
        callbacks.each do |callback|
          begin
            @__ext_default = default
            result = run_callback(callback, options)
          ensure
            @__ext_default = nil
          end

          next if Chanko::Aborted == result
          succeeded_callbacks << callback
          next unless result
          buffer.safe_concat(result)
        end
        return buffer if succeeded_callbacks.present?
        return ActiveSupport::SafeBuffer.new unless default
        run_callback(default, options)
      end

      def run_default
        return nil unless @__ext_default
        result = run_callback(@__ext_default, {:type => :plain, :capture => view?})
      end


      def str_or_nil(str)
        str.is_a?(String) ? str : nil
      end
      private :str_or_nil
    end
  end
end




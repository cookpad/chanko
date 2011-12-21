module Chanko
  class NoExtError < StandardError; end
  class NotAllowedError < StandardError; end
  module MethodProxy
    def self.included(obj)
      obj.send(:include, Methods)
      obj.extend Methods
    end

    module Methods
      def ext(_ext_label=nil, &block)
        ext_label = _ext_label || Chanko::Loader.current_scope
        raise NoExtError unless ext_label

        unless ext = Chanko::Loader.load_extension(ext_label)
          return nil if block_given?
          return Chanko::MethodProxy::NullProxy.new
        end

        unless block_given?
          return Chanko::MethodProxy::Proxy.new(self, ext)
        end

        begin
          Chanko::Loader.push_scope(ext_label) if _ext_label
          begin
            yield Chanko::Loader.fetch(ext_label)
          rescue ::Exception => e
            Chanko::ExceptionNotifier.notify("unknown error #{_ext_label}", false,
                                     :exception => e,
                                     :key => "method_proxy unknown error #{_ext_label}",
                                     :context => self,
                                     :backtrace => e.backtrace[0..20]
                                    )
          end
        ensure
          Chanko::Loader.pop_scope if _ext_label
        end
      end
    end

    class NullProxy
      def method_missing(name, *args, &block)
        nil
      end
    end

    class Proxy
      def initialize(obj, ext)
        @obj, @ext = obj, ext
      end
      attr_accessor :ext, :obj

      def active?(_options={})
        options = _options.is_a?(Hash) ? _options : {}
        @ext.active?(@obj, options)
      end
      alias_method :judge?, :active?

      def ext_method(name)
        "__#{@ext.name.underscore}__#{name}"
      end

      def method_missing(name, *args, &block)
        @obj.send(ext_method(name), *args, &block)
      end

      def label(name)
        ext_method(name)
      end
    end
  end
end


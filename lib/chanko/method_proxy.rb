module Chanko
  class NoExtError < StandardError; end
  class NotAllowedError < StandardError; end
  module MethodProxy
    def self.included(obj)
      obj.send(:include, Methods)
      obj.extend Methods
    end

    module Methods
      def unit(_unit_label=nil, &block)
        unit_label = _unit_label || Chanko::Loader.current_scope
        raise NoExtError unless unit_label

        unless ext = Chanko::Loader.load_unit(unit_label)
          return nil if block_given?
          return Chanko::MethodProxy::NullProxy.proxy
        end

        unless block_given?
          return Chanko::MethodProxy::Proxy.new(self, ext)
        end

        begin
          Chanko::Loader.push_scope(unit_label) if _unit_label
          begin
            unit = Chanko::Loader.fetch(unit_label)
            yield unit
          rescue ::Exception => e
            Chanko::ExceptionNotifier.notify("unknown error #{_unit_label}", unit.raise_error?,
                                     :exception => e,
                                     :key => "method_proxy unknown error #{_unit_label}",
                                     :context => self,
                                     :backtrace => e.backtrace[0..20]
                                    )
          end
        ensure
          Chanko::Loader.pop_scope if _unit_label
        end
      end
      alias_method :ext, :unit
    end

    class NullProxy
      def self.proxy
        @null_proxy ||= self.new
      end

      def method_missing(name, *args, &block)
        nil
      end
    end

    class Proxy
      def initialize(obj, unit)
        @obj, @unit = obj, unit
      end
      attr_accessor :unit, :obj

      def active?(_options={})
        options = _options.is_a?(Hash) ? _options : {}
        @unit.active?(@obj, options)
      end
      alias_method :judge?, :active?

      def unit_method_name(name)
        "__#{@unit.name.underscore}__#{name}"
      end
      alias_method :label, :unit_method_name

      def method_missing(name, *args, &block)
        @obj.send(unit_method_name(name), *args, &block)
      end
    end
  end
end

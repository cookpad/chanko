module Chanko
  module UnitProxyProvider
    extend ActiveSupport::Concern

    included do
      extend UnitProxyProvider
    end

    # Define #unit method in this class when #unit is called in first time.
    # Change Config.proxy_method_name if you want to change this method name.
    def method_missing(method_name, *args, &block)
      if Array.wrap(Config.proxy_method_name).include?(method_name)
        UnitProxyProvider.class_eval do
          define_method(method_name) do |*_args|
            name = _args.first || Function.current_unit.try(:unit_name)
            if name && unit = Loader.load(name)
              UnitProxy.new(unit, self)
            end
          end
        end
        send(method_name, args.first)
      else
        super
      end
    end
  end
end

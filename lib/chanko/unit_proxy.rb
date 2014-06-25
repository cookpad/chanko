require "delegate"

module Chanko
  class UnitProxy
    attr_reader :unit

    def self.generate_prefix(unit_name)
      "__#{unit_name}_"
    end

    def initialize(unit, context)
      @unit    = unit
      @context = context
    end

    def active?(options = {})
      @unit.active?(@context, options)
    end

    private

    def prefix
      self.class.generate_prefix(@unit.unit_name)
    end

    def method_missing(method_name, *args, &block)
      @context.send("#{prefix}#{method_name}", *args, &block)
    end

    def respond_to_missing?(method_name, include_private)
      @context.respond_to?("#{prefix}#{method_name}")
    end
  end
end

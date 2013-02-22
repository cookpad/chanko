module Chanko
  class ActiveIf
    class << self
      def define(label, &block)
        definitions[label] = block
      end

      def find(label)
        definitions[label]
      end

      def definitions
        @definitions ||= {}
      end

      def clear
        definitions.clear
      end
    end

    attr_reader :conditions, :options

    def initialize(*conditions, &block)
      @options    = conditions.extract_options!
      @conditions = conditions
      @block      = block
    end

    def active?(context, options = {})
      blocks.all? {|block| block.call(context, options) }
    end

    def blocks
      @blocks ||= begin
        conditions.map do |condition|
          condition.is_a?(Any) ? condition.to_block : self.class.find(condition)
        end << @block
      end.compact
    end

    class Any
      def initialize(*labels)
        @labels = labels
      end

      def to_block
        proc do |context, options|
          definitions.any? do |definition|
            definition.call(context, options)
          end
        end
      end

      def definitions
        @labels.map {|label| ActiveIf.find(label) }
      end
    end
  end
end

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
          Block.new(condition)
        end << @block
      end.compact
    end

    class Block
      def initialize(*conditions)
        @conditions = conditions
      end

      def call(context, options)
        block.call(context, options)
      end

      def block
        condition = @conditions.first
        condition.is_a?(Block) ? condition : ActiveIf.find(condition)
      end
    end

    class Any < Block
      def block
        proc do |context, options|
          @conditions.any? do |condition|
            Block.new(condition).call(context, options)
          end
        end
      end
    end

    class None < Block
      def block
        proc do |context, options|
          @conditions.none? do |condition|
            Block.new(condition).call(context, options)
          end
        end
      end
    end
  end
end

module Chanko
  class ActiveIf
    mattr_accessor :blocks, :files, :loaded, :definitions, :expanded_judgements
    self.files = []
    self.expanded_judgements = []
    self.definitions = {}

    def initialize(*names, &block)
      @options = names.last.is_a?(Hash) ? names.pop : {}
      @blocks = names.map do |name|
        case name
        when Chanko::ActiveIf::Any
          name.block
        else
          self.class.fetch(name, @options[:raise])
        end
      end
      @blocks << block if block
      @blocks.compact!
      @blocks
    end

    def active?(context, options={})
      result = self.class.run_expanded_judgements(context, options)
      return result unless result.nil?
      return !!self.class.default.call(context, options) if @blocks.blank?
      @blocks.each do |active_if|
        case active_if
        when true, false
          return active_if
        else
          return false unless !!active_if.call(context, options)
        end
      end
      return true
    end
    alias_method :enabled?, :active?


    class<<self
      def default
        Chanko.config.default_active_if || lambda { :false }
      end

      def define(name, &block)
        self.definitions[name.to_sym] = block
      end

      def load_definitions!
        if Chanko.config.cache_classes
          return if self.loaded
          files.each { |file| require file }
          self.loaded = true
        else
          files.each { |file| require_dependency file.to_s }
        end
      end

      def fetch(name, raise_error = false)
        load_definitions!
        result = self.definitions[name.to_sym]
        return result unless result.nil?
        Chanko::ExceptionNotifier.notify("missing Activeif definition #{name}", raise_error, :exception_klass => Chanko::Exception::MissingActiveIfDefinition)
        Chanko::ActiveIf.default
      end

      def run_expanded_judgements(context, options)
        self.expanded_judgements.each do |judge|
          result = judge.call(context, options)
          next if result.nil?
          return result
        end
        return nil
      end
    end

    class Any
      def initialize(*symbols)
        @blocks = symbols.map do |sym|
          Chanko::ActiveIf.fetch(sym)
        end
        @blocks.compact!
      end

      def block
        lambda do |context, options|
          @blocks.any? do |active_if_block|
            !!active_if_block.call(context, options)
          end
        end
      end
    end
  end
end

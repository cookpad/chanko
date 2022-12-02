require "pathname"
module Chanko
  module Loader
    class MissingEagarLoadSettingError < StandardError; end

    class << self
      delegate :load, :cache, :eager_load_units!, to: "loader"
    end

    def self.loader
      zeitwerk? ? ZeitwerkLoader : ClassicLoader
    end

    def self.zeitwerk?
      Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
    end

    def self.classic?
      !zeitwerk?
    end

    def self.prepare_eager_load(mode: )
      if mode == :zeitwerk && zeitwerk?
        self.loader.prepare_eager_load
      elsif mode == :classic && classic?
        self.loader.prepare_eager_load
      end
    end

    class ZeitwerkLoader
      def self.load(name)
        self.new(name).load
      end

      def self.cache
        # backward compatibility
        { }
      end

      def self.eager_load_units!
        # Zeitwerk load chanko units as default
      end

      def self.prepare_eager_load
        add_unit_directory_to_eager_load_paths
        Rails.autoloaders.main.collapse(Chanko::Config.units_directory_path + '/*')
        Rails.autoloaders.main.ignore(Chanko::Config.units_directory_path + '/*/spec*')
      end

      def self.add_unit_directory_to_eager_load_paths
        path = Chanko::Config.units_directory_path

        unless Rails.configuration.eager_load_paths.include?(path)
          Rails.configuration.eager_load_paths << path
        end
      end

      def initialize(name)
        @name = name
      end

      def load
        constantize
      rescue NameError
        # Chanko never raise error even if the constant fails to reference
        nil
      end

      def constantize
        @name.to_s.camelize.constantize
      end
    end

    class ClassicLoader
      def self.cache
        @cache ||= {}
      end

      def self.eager_load_units!
        Pathname.glob("#{Chanko::Config.units_directory_path}/*").select(&:directory?).each do |path|
          Chanko::Loader::ClassicLoader.load(path.basename.to_s.to_sym)
        end
      end

      def self.prepare_eager_load
        raise MissingEagarLoadSettingError if Rails.configuration.eager_load.nil?

        if Rails.configuration.eager_load
          ruleout_unit_files_from_rails_eager_loading
        end
      end

      def self.ruleout_unit_files_from_rails_eager_loading
        Rails.configuration.eager_load_paths.delete(Chanko::Config.units_directory_path)
      end

      def self.load(name)
        self.new(name).load
      end

      def self.load_from_cache(name)
        self.cache[name]
      end

      def self.save_to_cache(name, unit)
        self.cache[name] = unit
      end

      def initialize(name)
        @name = name
      end

      def load
        load_from_cache.then do |unit|
          next unit unless unit.nil?
          load_from_file_and_store_to_cache
        end
      end

      def load_from_file_and_store_to_cache
        add_autoload_path
        constantize.tap do |unit|
          self.class.save_to_cache(@name, unit)
        end
      rescue Exception => exception
        ExceptionHandler.handle(exception)
        self.class.save_to_cache(@name, false)
        nil
      end

      def load_from_cache
        self.class.load_from_cache(@name)
      end

      def add_autoload_path
        ActiveSupport::Dependencies.autoload_paths << autoload_path
        ActiveSupport::Dependencies.autoload_paths.uniq!
      end

      def autoload_path
        "#{Config.units_directory_path }/#{@name}"
      end

      def constantize
        @name.to_s.camelize.constantize
      end
    end
  end
end

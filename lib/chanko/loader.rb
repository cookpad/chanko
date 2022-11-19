require "pathname"
module Chanko
  module Loader
    class << self
      delegate :load, :cache, :prepare_eager_load, :eager_load_units!, to: "loader"
    end

    def self.loader
     zeitwerk? ? ZeitwerkLoader : ClassicLoader
    end

    def self.zeitwerk?
      Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
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
      end

      def self.add_unit_directory_to_eager_load_paths
        path = Chanko::Config.units_directory_path
        unless Rails.configuration.eager_load_paths.include?(path)
          Rails.configuration.eager_load_paths << path
        end
      end

      def self.initialize_zeitwerk_settings
        Rails.autoloaders.main.collapse(Chanko::Config.units_directory_path + '/*')
        Rails.autoloaders.main.ignore(Chanko::Config.units_directory_path + '/*/spec*')
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
          Chanko::Loader::ClassicLoader.load(path.to_s.split("/").last.to_s)
        end
      end

      def self.prepare_eager_load
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

      def initialize(name)
        @name = name
      end

      def load
        if loaded?
          load_from_cache
        else
          load_from_file
        end
      end

      def loaded?
        cache[@name] != nil
      end

      def load_from_cache
        cache[@name]
      end

      def load_from_file
        add_autoload_path
        cache[@name] = constantize
      rescue Exception => exception
        ExceptionHandler.handle(exception)
        cache[@name] = false
        nil
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

      def cache
        self.class.cache
      end
    end
  end
end

require "pathname"

module Chanko
  class Loader
    class << self
      def load(unit_name)
        new(unit_name).load
      end

      def cache
        @cache ||= {}
      end

      def eager_load_units!
        Pathname.glob("#{Rails.root}/#{Config.units_directory_path}/*").select(&:directory?).each do |path|
          load(path.to_s.split("/").last.to_sym) rescue nil
        end
      end
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
      unless Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
        ActiveSupport::Dependencies.autoload_paths << autoload_path
        ActiveSupport::Dependencies.autoload_paths.uniq!
      end
    end

    def autoload_path
      Rails.root.join("#{directory_path}/#@name").to_s
    end

    def directory_path
      Config.units_directory_path
    end

    def constantize
      @name.to_s.camelize.constantize
    end

    def cache
      self.class.cache
    end
  end
end

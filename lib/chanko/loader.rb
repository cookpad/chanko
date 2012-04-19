require 'active_support/core_ext/hash/indifferent_access'

module Chanko
  module Loader
    mattr_accessor :units
    mattr_accessor :loaded
    mattr_accessor :current_scopes
    mattr_accessor :__invoked_units
    mattr_accessor :__requested_units
    self.units = ::HashWithIndifferentAccess.new

    class<<self
      def size
        units.size
      end

      def reset!
        self.units = ::HashWithIndifferentAccess.new if Rails.env.test?

        if Chanko.config.cache_classes
          self.loaded ||= ::HashWithIndifferentAccess.new
        else
          self.loaded = ::HashWithIndifferentAccess.new
        end

        self.current_scopes = []
        self.__invoked_units = []
        self.__requested_units = []

      end

      def paths(name)
        self.directories.map { |directory| File.join(directory, name) }
      end

      def javascripts(name)
        Chanko::Loader.paths(name).inject([]) do |js, path|
          js += Pathname.glob(File.join(path, 'javascripts/*.js'))
        end
      end

      def clear_cache!
        Chanko::Unit.clear_cache!
        self.reset!
        self.loaded = ::HashWithIndifferentAccess.new
      end

      def invoked(unit_names)
        self.__invoked_units.concat(Array.wrap(unit_names).map(&:to_s))
      end

      def requested(unit_names)
        unit_names = [unit_names] unless unit_names.is_a?(Array)
        unit_names = unit_names.map(&:to_s)
        self.__requested_units.concat(unit_names)
      end

      def fetch(unit_name)
        return nil unless self.load_unit(unit_name)
        unit = begin unit_name.to_s.singularize.camelize.constantize; rescue; end
        return nil unless unit
        return nil unless unit.ancestors.include?(Chanko::Unit)
        unit
      end

      def push_scope(label)
        self.current_scopes.push label
      end

      def pop_scope
        self.current_scopes.pop
      end

      def current_scope
        self.current_scopes.last
      end

      def invoked_units
        self.__invoked_units.uniq
      end

      def requested_units
        self.__requested_units.uniq
      end
      #don't expand models when unit_name receive nil
      def load_expander(unit_name)
        %w(models helpers).each do |targets|
          Chanko::Loader.directories.each do |directory|
            Pathname.glob(directory.join("#{unit_name}/#{targets}/*.rb")).sort.each do |target|
              require_dependency "#{target.dirname}/#{target.basename}"
            end
          end
        end

        unit_name.to_s.camelize.constantize.tap do |unit|
          unit.expand!
        end
      end
      private :load_expander

      def load_core(unit_name, options={})
        Chanko::Loader.directories.each do |directory|
          Pathname.glob(directory.join("#{unit_name}/#{unit_name}.rb")).sort.each do |filename|
            if require_or_updating_load("#{filename.dirname}/#{filename.basename}")
              Chanko::Unit.clear_function_cache(unit_name.to_s.classify)
            end
          end
        end

        begin
          self.loaded[unit_name.to_sym] = load_expander(unit_name)
        rescue NameError => e
          unless options[:skip_raise]
            Chanko::ExceptionNotifier.notify("missing #{unit_name}", false, :key => "#{unit_name} load module", :exception => e, :context => options[:context], :backtrace => e.backtrace[0..20])
          end
          self.loaded[unit_name.to_sym] = false
        end
        self.loaded[unit_name.to_sym] ||= false
        self.loaded[unit_name.to_sym]
      rescue Exception => e
        Chanko::ExceptionNotifier.notify("except #{unit_name}", false, :key => "#{unit_name} load module", :exception => e, :context => options[:context], :backtrace => e.backtrace[0..20])
        self.loaded[unit_name.to_sym] ||= false
        self.loaded[unit_name.to_sym]
      end
      private :load_core

      def load_unit(unit_name, options={})
        return loaded[unit_name.to_sym] if loaded?(unit_name)
        load_core(unit_name, options)
      end

      def loaded?(unit)
        !self.loaded[unit.to_sym].nil?
      end

      def register(obj)
        self.units[obj.name] = obj
      end

      def deregister(obj)
        self.units.delete(obj.name)
        Chanko::Helper.deregister(obj.name)
      end

      def load_path_file(file, root)
        @directories = Chanko::Directories.load_path_file(file, root)
      end

      def add_path(path)
        @directories ||= Chanko::Directories.new
        @directories.add(path)
      end

      def remove_path(path)
        @directories ||= Chanko::Directories.new
        @directories.remove(path)
      end

      def directories
        @directories ||= Chanko::Directories.new
        @directories.directories
      end
    end
  end
end

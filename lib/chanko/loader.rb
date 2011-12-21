require 'active_support/core_ext/hash/indifferent_access'

module Chanko
  module Loader
    mattr_accessor :extensions
    mattr_accessor :loaded
    mattr_accessor :current_scopes
    mattr_accessor :__invoked_extensions
    mattr_accessor :__requested_extensions
    self.extensions = ::HashWithIndifferentAccess.new

    class<<self
      def size
        extensions.size
      end

      def reset!
        self.extensions = ::HashWithIndifferentAccess.new if Rails.env.test?

        if Chanko.config.cache_classes
          self.loaded ||= ::HashWithIndifferentAccess.new
        else
          self.loaded = ::HashWithIndifferentAccess.new
        end

        self.current_scopes = []
        self.__invoked_extensions = []
        self.__requested_extensions = []

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

      def invoked(ext_names)
        ext_names = [ext_names] unless ext_names.is_a?(Array)
        ext_names = ext_names.map(&:to_s)
        self.__invoked_extensions.concat(ext_names)
      end

      def requested(ext_names)
        ext_names = [ext_names] unless ext_names.is_a?(Array)
        ext_names = ext_names.map(&:to_s)
        self.__requested_extensions.concat(ext_names)
      end

      def fetch(ext_name)
        return nil unless self.load_extension(ext_name)
        ext = begin ext_name.to_s.singularize.camelize.constantize; rescue; end
        return nil unless ext
        return nil unless ext.ancestors.include?(Chanko::Unit)
        ext
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

      def invoked_extensions
        self.__invoked_extensions.uniq
      end

      def requested_extensions
        self.__requested_extensions.uniq
      end
      #don't expand models when ext_name receive nil
      def load_expander(ext_name)
        %w(models helpers).each do |targets|
          Chanko::Loader.directories.each do |directory|
            Pathname.glob(directory.join("#{ext_name}/#{targets}/*.rb")).sort.each do |target|
              require_dependency "#{target.dirname}/#{target.basename}"
            end
          end
        end

        ext_name.to_s.camelize.constantize.tap do |ext|
          ext.expand!
        end
      end
      private :load_expander

      def load_core(ext_name, options={})
        Chanko::Loader.directories.each do |directory|
          Pathname.glob(directory.join("#{ext_name}/#{ext_name}.rb")).sort.each do |filename|
            if require_or_updating_load("#{filename.dirname}/#{filename.basename}")
              Chanko::Unit.clear_callback_cache(ext_name.to_s.classify)
            end
          end
        end

        begin
          self.loaded[ext_name.to_sym] = load_expander(ext_name)
        rescue NameError => e
          unless options[:skip_raise]
            Chanko::ExceptionNotifier.notify("missing #{ext_name}", false, :key => "#{ext_name} load module", :exception => e, :context => options[:context], :backtrace => e.backtrace[0..20])
          end
          self.loaded[ext_name.to_sym] = false
        end
        self.loaded[ext_name.to_sym] ||= false
        self.loaded[ext_name.to_sym]
      rescue Exception => e
        Chanko::ExceptionNotifier.notify("except #{ext_name}", false, :key => "#{ext_name} load module", :exception => e, :context => options[:context], :backtrace => e.backtrace[0..20])
        self.loaded[ext_name.to_sym] ||= false
        self.loaded[ext_name.to_sym]
      end
      private :load_core

      def load_extension(ext_name, options={})
        return loaded[ext_name.to_sym] if loaded?(ext_name)
        load_core(ext_name, options)
      end

      def loaded?(ext)
        !self.loaded[ext.to_sym].nil?
      end

      def register(obj)
        self.extensions[obj.name] = obj
      end

      def deregister(obj)
        self.extensions.delete(obj.name)
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

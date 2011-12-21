
module Chanko
  module UpdatingLoad
    module Loadable
      def self.included(obj)
        obj.class_eval do
          def require_or_updating_load(path)
            ActiveSupport::Dependencies.require_or_updating_load(path)
          end
        end
      end
    end

    module Dependencies
      def self.included(obj)
        obj.class_eval do
          @@timestamps = {}
          @@defined_classes = {}

          class<<self
            def reset_timestamps_and_defined_classes
              @@timestamps = {}
              @@defined_classes = {}
            end

            def require_or_updating_load(path)
              if Chanko.config.cache_classes
                return require(path.to_s)
              end
              absolute_path = expand_to_fullpath(path.to_s)
              return false unless file_updated?(absolute_path)
              save_timestamp(absolute_path)
              result = nil
              newly_defined_paths = new_constants_in(Object) do
                 Kernel.load absolute_path
              end
              @@defined_classes[absolute_path] = newly_defined_paths
              return true
            end

            def clear_defined_classes(path)
              absolute_path = expand_to_fullpath(path.to_s)
              return unless @@defined_classes[absolute_path]
              @@defined_classes[absolute_path].each do |klass|
                Object.send(:remove_const, klass)
              end
            end
            private :clear_defined_classes

            def expand_to_fullpath(path)
              if path =~ /\A\/.*/
                return path if File.exist?(path)
                return "#{path}.rb" if File.exist?("#{path}.rb")
                raise LoadError, "#{path} not found"
              end

              $:.each do |prefix|
                fullpath = "#{prefix}/#{path}.rb"
                next unless File.exist?(fullpath)
                return fullpath
              end
              raise LoadError, "#{path} not found"
            end
            private :expand_to_fullpath

            def file_updated?(path)
              absolute_path = expand_to_fullpath(path.to_s)
              return true unless @@timestamps[absolute_path]
              return false unless File.exist?(absolute_path)
              tv_sec = File.ctime(absolute_path).tv_sec
              @@timestamps[absolute_path] == tv_sec ? false : true
            end
            private :file_updated?

            def save_timestamp(path)
              return false unless File.exist?(path)
              @@timestamps[path] = File.ctime(path).tv_sec
            end
            private :save_timestamp
          end
        end
      end
    end
  end
end

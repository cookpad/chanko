module Chanko
  module Helper
    mattr_accessor :files
    self.files = {}
    def self.reset
      self.files.keys.each do |path|
        self.remove_old_methods_by_file_path(path)
      end
    end
    mattr_accessor :check_to_update_interval
    self.check_to_update_interval = 1.seconds

    def self.included(obj)
      return unless obj.instance_methods.map(&:to_s).include?('invoke')
      return if obj.instance_methods.map(&:to_s).include?('invoke_without_helper')
      obj.class_eval do
        def invoke_with_helper(*args, &block)
          options = args.extract_options!
          options = options.reverse_merge(:as => :view) unless self.is_a?(ApplicationController)
          args << options
          invoke_without_helper(*args, &block)
        end
        alias_method_chain :invoke, :helper
      end
    end

    def self.deregister(name)
      line = caller.detect { |c| c =~ /(.*#{name}.*\.rb).*/ }
      path = $1 || name
      return remove_old_methods_by_file_path(path)
    end

    def self.remove_old_methods_by_file_path(path)
      return unless self.files[path]
      return if self.files[path][:timestamp] > Time.now - check_to_update_interval
      self.files[path][:methods].each do |method|
        remove_method(method)
      end
      self.files[path][:methods] = []
    end

    def self.save_new_methods(name, methods)
      line = caller.detect { |c| c =~ /(.*#{name}.*\.rb).*/ }
      path = $1 || name
      self.files[path] ||= {}
      self.files[path][:timestamp] = Time.now
      self.files[path][:methods] ||= []
      self.files[path][:methods].concat(methods)
    end

    def self.rename_new_methods(name, new_methods)
      methods = []
      new_methods.each do |new_method|
        prefix_new_method = Chanko::Unit.unit_method_name(name, new_method)
        methods << prefix_new_method
        self.class_eval do
          alias_method prefix_new_method, new_method
          remove_method(new_method)
        end
      end
      return methods
    end

    def self.register(_name, &block)
      name = _name.underscore
      self.deregister(name)
      tmp_methods = self.instance_methods(false)
      self.class_eval(&block)
      new_methods = self.instance_methods(false) - tmp_methods
      renamed_new_methods = self.rename_new_methods(name, new_methods)
      self.save_new_methods(name, renamed_new_methods)
    end
  end
end

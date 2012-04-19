module Chanko
  module Unit
    autoload 'Default', 'chanko/unit/default'

    mattr_accessor :__functions_cache
    mattr_accessor :__ancestors_cache
    mattr_accessor :__eager_paths
    def self.clear_cache!
      self.__ancestors_cache = Chanko::Tools.nested_hash(1)
      self.__functions_cache = Chanko::Tools.nested_hash(2)
      self.__eager_paths = Hash.new
    end
    clear_cache!

    def self.clear_function_cache(name)
      return Chanko::Unit.__functions_cache[name] = Chanko::Tools.nested_hash(1)
    end

    def self.included(obj)
      obj.extend(ClassMethods)

      obj.class_eval do
        class<<self
          def default=(val)
            @default = val
          end

          def default
            @default || false
          end

          def unitize!
            Chanko::Loader.register(self)
            @functions = {}
            @active_if = Chanko::ActiveIf.new
          end
        end
      end
      obj.unitize!
    end

    def self.unit_method_name(unit_name, method)
      "__#{unit_name}__#{method}"
    end

    module ModelsClassMethods
      def expand(klass_name, &block)
        name = "#{klass_name}"
        begin
          klass = klass_name.constantize
        rescue NameError => e
          Chanko::ExceptionNotifier.notify("expand name error #{self.name} #{klass_name}", false,
                                   :key => "#{self.name} expand error", :exception => e,
                                   :context => self, :backtrace => e.backtrace[0..20]
                                  )
          return false
        end

        if self.constants.map(&:to_s).include?(name)
          m = self.const_get(name)
        else
          m = self.const_set(name, Module.new)
          m.send(:include, Chanko::ActiveRecord::Expand)
          m.prefix = self.expand_prefix
        end
        m.class_eval(&block)
        m.expanded = false
      end
    end

    module ClassMethods
      extend ActiveSupport::Memoizable
      attr_reader :shared_methods

      def active_if(*symbols, &block)
        @active_if = Chanko::ActiveIf.new(*symbols, &block)
      end
      alias_method :judge, :active_if

      def active?(context=nil, options={})
        begin
          options = options.merge(:unit => self)
          @active_if.enabled?(context, options)
        rescue ::Exception => e
          Chanko::ExceptionNotifier.notify("Activeif definition #{self.name} raised", false,
                                   :key => "#{self.name}_active?",
                                   :context => context,
                                   :backtrace => e.backtrace[0..20],
                                   :exception => e
                                  )
                                  return false
        end
      end
      alias_method :enabled?, :active?

      def any(*symbols)
        Chanko::ActiveIf::Any.new(*symbols)
      end
      private :any

      def unit_name
        self.name.split("::").first.underscore
      end
      memoize :unit_name

      def expand_prefix
        "__#{unit_name}__"
      end
      memoize :expand_prefix

      def models_module
        return self.const_get("Models") if self.constants.map(&:to_s).include?("Models")
        expand_prefix = self.expand_prefix
        models_module = self.const_set("Models", Module.new do
          extend ModelsClassMethods
          mattr_accessor :expand_prefix
          self.expand_prefix = expand_prefix
        end)
        return models_module
      end
      private :models_module

      def models(&block)
        models_module.class_eval(&block)
      end
      private :models

      def helpers(&block)
        Chanko::Helper.register(self.name, &block)
      end

      def scope(scope, &block)
        if scope.kind_of?(Class)
          scope_klass = scope
        else
          scope_klass_string =  Chanko::Aliases.alias(scope)
          begin
            scope_klass = scope_klass_string.constantize
          rescue NameError => e
            Chanko::ExceptionNotifier.notify("scope '#{scope_klass_string}' is unable to constantize", false,
                                   :key => "#{self.name} expand error", :exception => e,
                                   :backtrace => e.backtrace[0..20])
          end
        end
        @scope = scope_klass
        yield
        @scope = nil
      end
      private :scope

      def function(label, options = {}, &block)
        self.add(@scope, label, block, options)
      end
      alias_method :callback, :function
      private :callback
      private :function

      def underscore
        name.to_s.underscore
      end
      memoize :underscore

      def css_name
        underscore
      end

      def add(scope, label, block, options={})
        @functions[scope] ||= {}
        @functions[scope][label] = Chanko::Function.new(label, self, options, &block)
        @keys = nil
      end

      def scopes
        @keys ||= @functions.keys
      end

      def absolute_view_paths
        view_paths.map do |view_path|
          if view_path[/^\//]
            view_path
          else
            File.join(Rails.root, view_path).to_s
          end
        end
      end
      private :absolute_view_paths

      def view_paths
        Chanko::Loader.directories.map {|directory| File.join(directory, "#{self.name.to_s.underscore}/views") }
      end

      def attach_view_paths(scope)
        return unless scope.respond_to?("view_paths")
        absolute_view_paths.each do |_path|
          if Chanko.config.cache_classes
            path = Chanko::Unit.__eager_paths[_path]
          end
          path ||= _path

          resolver = if Chanko.config.view_resolver
            Chanko.config.view_resolver.new(path)
          else
            if Rails::VERSION::MINOR >= 1
              ActionView::OptimizedFileSystemResolver.new(path)
            else
              path
            end
          end

          if Rails::VERSION::MINOR >= 2
            scope.view_paths.paths.unshift(resolver)
          else
            scope.view_paths.unshift(resolver)
          end
        end
      end
      private :attach_view_paths

      def detach_view_paths(scope)
        return unless scope.respond_to?("view_paths")
        absolute_view_paths.size.times do |path|
          if Rails::VERSION::MINOR >= 2
            shifted_path  = scope.view_paths.paths.shift
          else
            shifted_path  = scope.view_paths.shift
          end
          Chanko::Unit.__eager_paths[shifted_path] = shifted_path
        end
      end
      private :detach_view_paths

      def attach(scope, &block)
        return yield if default?
        begin
          attach!(scope)
          yield
        ensure
          detach!(scope)
        end
      end

      def attach!(scope)
        attach_view_paths(scope)
        scope.attached_unit_classes ||= []
        scope.attached_unit_classes.push(self)
      end

      def detach!(scope)
        detach_view_paths(scope)
        scope.attached_unit_classes.pop if scope.respond_to?("attached_unit_classes")
      end

      def ancestors?(scope, context)
        if Chanko.config.cache_classes
          scope_key = scope
          context_key = context
        else
          scope_key = scope.name
          context_key = context.name
        end

        unless (result = Chanko::Unit.__ancestors_cache[scope_key][context_key]).blank?
          return result
        end

        result = context.ancestors.any? do |anc|
          (Chanko.config.cache_classes ? anc : anc.name) == scope_key
        end
        Chanko::Unit.__ancestors_cache[scope_key][context_key] = result
        return result
      end
      private :ancestors?

      def default?
        !!self.default
      end
      memoize :default?

      def functions(context, label, active_if_options={}, options = {})
        return [] unless active?(context, active_if_options)

        label = label.kind_of?(Symbol) ? label : label.to_sym
        context_class =  Chanko::Aliases.alias(options[:as] || context.class)
        context_class = context_class.constantize if context_class.is_a?(String)
        scope_key = Chanko.config.cache_classes ? context_class : context_class.name
        cache =  Chanko::Unit.__functions_cache[self.name][scope_key][label]
        return cache unless cache.nil?

        cbks = []
        scopes.each do |scope|
          next unless ancestors?(scope, context_class)
          function = get_function(scope, label)
          cbks << function if function
        end
        Chanko::Unit.__functions_cache[self.name][scope_key][label] = cbks

        return cbks.dup unless cbks.blank?

        Chanko::ExceptionNotifier.notify("missing functions #{self.name}##{label}", false,
                                 :exception_klass => Chanko::Exception::MissingFunction,
                                 :key => "missing function #{self.name}",
                                 :context => self
                                )
                                return []
      end

      def get_function(scope, label)
        @functions[scope] ||= {}
        @functions[scope][label]
      end
      private :get_function

      def add_shared_method(name, &block)
        @shared_methods ||= {}
        @shared_methods[name.to_sym] = block
      end
      alias_method :shared, :add_shared_method

      def shared_method(name)
        @shared_methods ||= {}
        @shared_methods[name]
      end

      def expand!
        return unless self.constants.map(&:to_s).include?("Models")
        models = self.const_get("Models")
        models.constants.each do |const|
          expander = models.const_get(const)
          object = Object.const_get(const)
          expander.attach(object)
        end
      end
    end
  end
end

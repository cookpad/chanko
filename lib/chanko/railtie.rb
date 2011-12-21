require "rails"

module Chanko
  load_klasses = %w(aborted log loader unit helper method_proxy invoker controller tools)
  load_klasses += %w(test callback callbacks active_if directories aliases exception exception_notifier expand active_record updating_load)
  load_klasses.each do |klass|
    autoload klass.camelize, "chanko/#{klass}"
  end

  class Railtie < Rails::Railtie
    initializer 'chanko.attach' do |app|
      ::ActionView::Base.send(:include, Chanko::Invoker)
      ::ActionController::Base.send(:include, Chanko::Invoker)

      ::ActiveRecord::Base.send(:include, Chanko::MethodProxy)
      ::ActiveRecord::Relation.send(:include, Chanko::MethodProxy)
      if Rails::VERSION::MINOR > 0
        ::ActiveRecord::Associations::CollectionAssociation.send(:include, Chanko::MethodProxy)
      else
        ::ActiveRecord::Associations::AssociationProxy.send(:include, Chanko::MethodProxy)
      end
      ::ActionView::Base.send(:include, Chanko::MethodProxy)
    end

    initializer 'chanko.active_support' do |app|
      ::ActiveSupport::Dependencies.send(:include, Chanko::UpdatingLoad::Dependencies)
      ::ActiveSupport::Dependencies::Loadable.send(:include, Chanko::UpdatingLoad::Loadable)
    end

    initializer 'chanko.config' do |app|
      require 'chanko/config'
    end

    initializer 'chanko.initialize' do |app|
      ActiveSupport::Dependencies.autoload_paths += %W(#{app.root}/spec/fixtures/lib)
      Chanko::Loader.reset!
    end

    initializer 'chanko.extend_controller' do |app|
      ActionController::Base.class_eval { class << self; self; end }.class_eval do
        def inherited_with_reset_chanko(subclass)
          result = inherited_without_reset_chanko(subclass)
          return result unless subclass.superclass == ActionController::Base
          subclass.class_eval do
            include Chanko::Controller
            prepend_before_filter :reset_chanko
            def reset_chanko
              Chanko::Loader.reset!
            end
            private :reset_chanko
          end
          return result
        end
        alias_method_chain :inherited, :reset_chanko
      end
    end
  end
end

module Chanko
  class Railtie < Rails::Railtie
    initializer "chanko.include", before: "eager_load!" do |app|
      ActiveSupport.on_load :action_view do
        ::ActionView::Base.send(:include, Helper, Invoker, UnitProxyProvider)
      end
      ActiveSupport.on_load :action_controller do
        ::ActionController::Base.send(:include, Controller, Invoker, UnitProxyProvider)
      end
      ActiveSupport.on_load :active_record do
        ::ActiveRecord::Base.send(:include, UnitProxyProvider)
        ::ActiveRecord::Relation.send(:include, UnitProxyProvider)
        ::ActiveRecord::Associations::CollectionAssociation.send(:include, UnitProxyProvider)
      end
    end

    initializer("chanko.support_zeitwerk", before: "chanko.include") do |app|
      if Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
        Chanko::Loader::ZeitwerkLoader.initialize_zeitwerk_settings
      end
    end

    initializer("chanko.prepare_eager_load", before: :set_autoload_paths) do |app|
      Chanko::Loader.prepare_eager_load
    end

    initializer("chanko.eager_load_units", after: :set_autoload_paths) do |app|
      if Rails.configuration.eager_load
        # This is why we need handmade eager-loading
        # https://github.com/cookpad/chanko/pull/38
        Chanko::Loader.eager_load_units!
      end
    end
  end
end

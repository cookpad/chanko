module Chanko
  class Railtie < Rails::Railtie
    initializer "chanko.include", before: :eager_load! do |app|
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

    initializer("chanko.zeitwerk.prepare_eager_load", before: :set_autoload_paths) do |app|
      # zeitwerk freezes autoload_paths after :set_autoload_paths.
      # So we need to prepare before set_autoload_paths
      Chanko::Loader.prepare_eager_load(mode: :zeitwerk)
    end

    initializer("chanko.classic.prepare_eager_load", after: :load_environment_config) do |app|
      # At this stage, config.eager_load cannot be determined to be true or false.
      # But classic loader does not freeze paths on :set_autoload_paths.
      # After all, It's ok if it is executed after :set_autoload_paths on Rails6(classic).
      Chanko::Loader.prepare_eager_load(mode: :classic)
    end

    initializer("chanko.eager_load_units", before: :eager_load!) do |app|
      # This is why we need handmade eager-loading
      # https://github.com/cookpad/chanko/pull/38
      Chanko::Loader.eager_load_units!
    end
  end
end

module Chanko
  class Railtie < Rails::Railtie
    initializer "chanko" do |app|
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

    initializer("chanko.prevent_units_directory_from_eager_loading", before: :set_autoload_paths) do |app|
      if Chanko::Config.eager_load
        Rails.configuration.eager_load_paths.delete(Rails.root.join(Chanko::Config.units_directory_path).to_s)
      end
    end

    initializer("chanko.eager_load_units") do |app|
      if Chanko::Config.eager_load
        Chanko::Loader.eager_load_units!
      end
    end
  end
end

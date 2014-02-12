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
  end
end

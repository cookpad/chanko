module Chanko
  class Railtie < Rails::Railtie
    initializer "chanko" do |app|
      ::ActionView::Base.send(:include, Helper, Invoker, UnitProxyProvider)
      ::ActionController::Base.send(:include, Controller, Invoker, UnitProxyProvider)
      ::ActiveRecord::Base.send(:include, UnitProxyProvider)
      ::ActiveRecord::Relation.send(:include, UnitProxyProvider)
      ::ActiveRecord::Associations::CollectionAssociation.send(:include, UnitProxyProvider)
    end
  end
end

Chanko::Application.routes.draw do
  resources :users do
  end
  match '/:controller(/:action(/:id))'
end

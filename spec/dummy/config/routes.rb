Dummy::Application.routes.draw do
  root :to => "entries#index"

  resources :entries
end

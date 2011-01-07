Api::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  resources :platforms, :only => [:index, :show] do
    resources :environments, :only => [:index, :show]
    resources :sites, :only => [:index, :show] do
      member do
        get :status
      end
      resources :environments, :only => [:index, :show]
      resources :clusters, :only => [:index, :show] do
        resources :nodes, :only => [:index, :show]
      end
      resources :jobs
      resources :deployments
    end
  end
  match '*resource/versions' => 'versions#index', :via => [:get]
  match '*resource/versions/:id' => 'versions#show', :via => [:get]

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "root#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end

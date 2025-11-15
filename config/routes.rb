Rails.application.routes.draw do
  namespace :instrumentation do
      # Add your routes here
    end
  namespace :electrical do
      # Add your routes here
    end
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get 'site/home'
    get 'site/help'
    get 'site/about'
    get 'site/contact'
    get 'site/test_icons'

    devise_for :users, controllers: {
      sessions: 'users/sessions'
    }
    
    resources :users, only: [:show, :index]
    
    resources :projects do
      resources :disciplines, shallow: true
      collection do
        get "select"
        post "set"
      end
    end
    
    # Tagable models have top level new and create routes to allow creation of tagable and tag in a single operation
    # Tagables have index overridden from shallow, there is no sense in nesting a 1:1 relationship.
    resources :cables, :motors, :light_ccts, :socket_ccts, only: [:index, :new, :create]
    resources :switchboards, only: [:index, :new, :create] do
      resources :circuits, only: [:index, :new, :create]
    end

    # Then define the shallow nested routes
    resources :tags, shallow: true do
      resources :cables, :motors, :light_ccts, :socket_ccts, except: [:index]
      resources :switchboards, except: [:index] do
        resources :circuits, except: [:index]
      end
      resources :demands, only: [:new, :create]
      collection do
        get :schema_data
      end
    end

    # Define top level index routes for circuits, demands, to allow complete load listings.
    resources :circuits, :demands, only: [:index]
    
    resources :cable_types
    
    # Demands routes
    resources :demands, except: [:new, :create]

    # Routes for the RBAC system. 
    # Destroy requires both the role id and the user id to allow rolify to remove the correct HABTM entry.
    resources :users, only: [] do
      resources :roles, only: [:destroy]
    end
    # Role creation is attached to the index view for global and resource wide roles.
    resources :roles, only: [:index, :new, :create]
  end

  # Defines the root path route ("/")
  root to: 'site#home'
  
  # Error handling - custom error pages
  match '/403', to: 'errors#forbidden', via: :all, as: :forbidden
  match '/404', to: 'errors#not_found', via: :all, as: :not_found
  match '/409', to: 'errors#conflict', via: :all, as: :conflict
  match '/422', to: 'errors#unprocessable_entity', via: :all, as: :unprocessable_entity
  match '/500', to: 'errors#internal_server_error', via: :all, as: :internal_server_error
  
  # Catch-all route for 404s - must be last
  match '*unmatched', to: 'errors#not_found', via: :all

  # Handle Chrome DevTools JSON request
get "/.well-known/appspecific/com.chrome.devtools.json", to: proc { [200, { "Content-Type" => "application/json" }, []] }
end

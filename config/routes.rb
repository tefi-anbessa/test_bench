Rails.application.routes.draw do
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
      collection do
        get "select"
        post "set"
      end
    end
    
    # Tagable models are shallow nested under tags to allow creation of tags by attaching to an existing tag
    resources :tags, shallow: true do
      resources :cables, :motors, :light_ccts, :socket_ccts, except: [:index]
      resources :switchboards, except: [:index] do
        resources :circuits, except: [:index]
      end
    end
    # Tagable models also have new and create routes to allow creation of tagable and tag in a single operation
    # Tagables have index overridden from shallow, there is no sense in nesting a 1:1 relationship.
    resources :cables, :motors, :light_ccts, :socket_ccts, only: [:index, :new, :create]
    resources :switchboards, only: [:index, :new, :create] do
      resources :circuits, only: [:index, :new, :create]
    end
    resources :cable_types
    
    # Demands routes
    resources :demands

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
  
  # Error handling - only custom 403 page, others use static files in public/
  get '/403', to: 'errors#forbidden', as: :forbidden
end

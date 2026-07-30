Rails.application.routes.draw do

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get 'site/home'
    get 'site/help'
    get 'site/about'
    get 'site/contact'
    get 'site/test_icons'

    # Devise routes
    devise_for :users, controllers: {
      sessions: 'users/sessions'
    }
    
    # Additional routes for users UI (presentation only)
    resources :users, only: [:show, :index]
    
    # App wide resources
    resources :projects do
      collection do
        get "select"
        post "set"
      end

      # Project nested index routes
      resources :tags, :documents, :doc_types, :electrical_cable_types, only: [:index]

      # Project nested resources
      resources :disciplines, shallow: true do
        get :schema, on: :member, constraints: { format: 'json' }
        # Discipline nested resources
        # Tagable models have discipline level new and create routes to allow creation 
        # of tagable and tag in a single operation
        # Tagables override index from the shallow nesting under tags, 
        # there is no sense in nesting a 1:1 relationship.
        namespace :electrical do
          # INSERTION POINT 1 FOR SUBMODULES
          # INSERTION POINT 1 FOR TAGABLE GENERATOR
          resources :heaters, :cables, :motors, :light_ccts, 
                    :socket_ccts, only: [:index, :new, :create]
          resources :switchboards, only: [:index, :new, :create] do
            resources :circuits, shallow: true
          end
          # Define discipline level index routes for circuits, demands, to allow complete 
          # discipline load listings.
          resources :circuits, :demands, only: [:index]
        end # electrical namespace
        # INSERTION POINT 1 FOR MODULE GENERATOR
        resources :tags, shallow: true do
          # tagables differ from shallow routes because they require index to be treated
          # like a member route. No point in nesting index under tag.
          namespace :electrical do
          # INSERTION POINT 2 FOR TAGABLE GENERATOR
            resources :heaters, :cables, :motors, :light_ccts, 
              :socket_ccts, :switchboards, except: [:index]
            # Demands are special case, not tagable but require tagable for create and update, 
            # nested under tag for this requirement.
            resources :demands, except: [:index]
          end
          # INSERTION POINT 2 FOR MODULE GENERATOR
        end # tag nested resources (tagables)
        # Continue discipline nested resources
        resources :documents, shallow: true do
          resources :issues
        end
        resources :doc_types
        namespace :electrical do
          resources :cable_types, shallow: true
        end
      end # discipline nested resources

      # Change namespace for change management
      namespace :change_management do
        resources :requests, shallow: true
      end
    end # project nested routes

    resources :source_formats

    # Routes for the RBAC system. 
    # Destroy requires both the role id and the user id to allow rolify to remove the correct HABTM entry.
    resources :users, only: [] do
      resources :roles, only: [:destroy]
    end
    # Role creation is attached to the index view for global and resource wide roles.
    resources :roles, only: [:index, :new, :create]

    resources :swatches
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
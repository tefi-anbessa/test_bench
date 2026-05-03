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
      resources :disciplines, shallow: true do
        get :schema, on: :member, constraints: { format: 'json' }
      end

      # Include routes for catalog type items which link directly to project.
      namespace :electrical do
        resources :cable_types, shallow: true
      end
    end

    namespace :document_control do
        resources :source_formats
    end

    # Top-level disciplines routes (shallow from projects nesting)
    resources :disciplines, only: [], shallow: true do
      resources :tags, :documents
      namespace :document_control do
        resources :doc_types
      end
    end
    
    # Tagable models have top level new and create routes to allow creation 
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
      # Define top level index routes for circuits, demands, to allow complete load listings.
      resources :circuits, :demands, only: [:index]
    end
    # INSERTION POINT 1 FOR MODULE GENERATOR
    # Change namespace for change management
    namespace :project_change do
      resources :requests
      # INSERTION POINT 1 FOR TAGABLE GENERATOR
      # Insert change member routes here with only: [:index, :new, :create]
    end

    # Then define the shallow nested routes which require the tag
    resources :tags, shallow: true, only: [] do
      namespace :electrical do
        # INSERTION POINT 2 FOR SUBMODULES
        # INSERTION POINT 2 FOR TAGABLE GENERATOR
        resources :heaters, :cables, :motors, :light_ccts, 
                  :socket_ccts, except: [:index]
        resources :switchboards, except: [:index]
        resources :demands, except: [:index]
      end
    # INSERTION POINT 2 FOR MODULE GENERATOR

    end

    # Routes for the RBAC system. 
    # Destroy requires both the role id and the user id to allow rolify to remove the correct HABTM entry.
    resources :users, only: [] do
      resources :roles, only: [:destroy]
    end
    # Role creation is attached to the index view for global and resource wide roles.
    resources :roles, only: [:index, :new, :create]

    resources :swatches
    resources :documents, only: [], shallow: true do
      namespace :document_control do
        resources :issues
      end
    end
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
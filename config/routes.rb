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

      # Project nested routes
      resources :disciplines, shallow: true do
        get :schema, on: :member, constraints: { format: 'json' }
      end
      # Namespace for change management
      namespace :change_management do
        resources :requests, shallow: true
      end
    end # project nested routes

    resources :disciplines, shallow: true, only: [] do
      # Discipline nested routes
      # INSERTION POINT 1 FOR MODULE GENERATOR
      resources :tags
      resources :documents, shallow: true do
        # Document nested resources
        resources :issues
          # Issue nested resources
      end # document nested routes
      resources :doc_types
      namespace :electrical do
        resources :cable_types
        resources :circuits, :demands, only: [:index]
      end
    end # discipline nested routes

    # Tag nested routes
    resources :tags, shallow: true, only: [] do
      namespace :electrical do
        # Demands are special case, not tagable but require tagable for create and update,
        # nested under tag for this requirement.
        resources :demands, except: [:index]
      end
    end # tag nested routes

    # Tagable routes
    resources :tags, only: [] do
      resource :tagable
    end
    resources :disciplines, only: [] do
      resource :tagable, only: [:new, :create], controller: :tagables
    end
    resources :disciplines, only: [] do
      resources :tagables, only: [:index]
    end

    # Child-of-tagable routes: models that belong to one specific tagable instance
    # (not a discipline), scoped only by that parent.
    namespace :electrical do
      resources :switchboards, only: [] do
        resources :circuits, shallow: true
      end
    end

    # Document nested routes
    resources :documents, shallow: true, only: [] do
    end # document nested routes

    # Issue nested routes
    resources :issues, shallow: true, only: [] do
    end # issue nested routes

    # Global resource routes
    resources :source_formats
    resources :swatches
    # Insertion point for non-nested routes

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
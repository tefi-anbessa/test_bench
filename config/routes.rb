Rails.application.routes.draw do
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get 'site/home'
    get 'site/help'
    get 'site/about'
    get 'site/contact'

    devise_for :users, controllers: {
        sessions: 'users/sessions'
      }
    resources :users, :only => [:show, :index]
    resources :projects do
      collection do
        get "select"
      end
      member do
        post "set"
      end
    end
    resources :tags, shallow: true do
      resources :switchboards, :except => [:index] do
        resources :circuits
      end
      resources :cables, :except => [:index]
      resources :light_ccts, :except => [:index]
      resources :socket_ccts, :except => [:index]
      resources :motors, :except => [:index]
    end
    resources :loads, :only => [:index]
    resources :switchboards, :only => [:index]
    resources :cables, :only => [:index]
    resources :cable_types

    resources :users, :only => [] do
      resources :roles, :only => [:destroy]
    end
    resources :roles, :only => [:index, :new, :create]
  end

  # Defines the root path route ("/")
  root to: 'site#home'
end

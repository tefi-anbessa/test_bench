Rails.application.routes.draw do
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get 'site/home'
    get 'site/help'
    get 'site/about'
    get 'site/contact'

    devise_for :users
    resources :users, :only => [:show, :index]
    resources :projects
    resources :tags, shallow: true do
      resources :loads, :except => [:index] do
        resources :switchboards, :except => [:index] do
          resources :circuits
        end
      end
      resources :cables, :except => [:index]
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

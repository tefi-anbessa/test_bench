Rails.application.routes.draw do
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get 'site/home'
    get 'site/help'
    get 'site/about'
    get 'site/contact'

    devise_for :users
    resources :users, :only => [:show, :index]
    end

  # Defines the root path route ("/")
  root to: 'site#home'
end

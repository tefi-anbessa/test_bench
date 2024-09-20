Rails.application.routes.draw do
  get 'site/home'
  get 'site/help'
  get 'site/about'
  get 'site/contact'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "site#home"
end

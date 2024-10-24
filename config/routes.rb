Rails.application.routes.draw do
  devise_for :users
  root to: 'counts#index'

  resources :deadlines, except: :show
  resources :expense_items, except: :show
  resources :counts, except: :show do
    member do
      get :stats, to: 'counts#stats'
    end
    resources :movements, except: [:show, :new]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end

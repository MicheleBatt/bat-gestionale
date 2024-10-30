Rails.application.routes.draw do
  devise_for :users
  root to: 'deadlines#index'

  resources :organizations, except: [:show, :new, :edit] do
    resources :memberships, except: [:show, :new, :edit]
    resources :deadlines, except: [:show, :new, :edit]
    resources :expense_items, except: [:show, :new, :edit]
    member do
      get :stats, to: 'organizations#stats'
    end
    resources :counts, except: [:show, :new, :edit] do
      member do
        get :stats, to: 'counts#stats'
      end
      resources :movements, except: [:show, :new, :edit]
    end
  end

  resources :users, except: [:create, :show, :new] do
    collection do
      post 'add'
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

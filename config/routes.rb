Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'
  resources :home, only: [:index] do
    collection do
      get :search
      get :page_google_results
    end
  end

  resources :sessions do
    collection do
      get :terminate_account
    end

    member do
      get :select_account
    end
  end

  resources :accounts, only: [:destroy]

  get "/auth/twitter/callback" => "sessions#create"

end

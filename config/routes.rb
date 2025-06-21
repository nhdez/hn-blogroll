require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  
  root 'main#index'
  get 'random', to: 'main#random_redirect'
  get 'csv', to: 'main#download_csv', as: 'download_csv'
  get 'index.opml', to: 'main#download_opml', as: 'download_opml'
  get 'posts', to: 'posts#index'
  get 'posts/:id', to: 'posts#show', as: 'post'
  
  # Blog submission workflow
  resources :submissions, only: [:new, :create, :show] do
    collection do
      get :guidelines
    end
  end
  get 'submit', to: 'submissions#new'
  
  resources :blogs, only: [:create, :show, :index] do
    resources :posts, only: [:index, :show]
  end
  
  namespace :api do
    namespace :v1 do
      resources :blogs, only: [:index, :show] do
        resources :posts, only: [:index, :show]
      end
      resources :posts, only: [:index, :show]
    end
  end
  
  namespace :admin do
    root 'blogs#index'
    
    resources :blogs do
      member do
        patch :approve
        patch :reject
        post :refresh_posts
        post :check_status
        post :update_karma
      end
      
      collection do
        get :pending
        get :approved
        get :rejected
        post :bulk_approve
        post :bulk_reject
      end
    end
    
    resources :posts, only: [:index, :show, :destroy]
    
    # Admin dashboard
    get 'dashboard', to: 'dashboard#index'
  end
end

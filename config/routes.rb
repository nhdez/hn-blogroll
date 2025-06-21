require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  
  root 'main#index'
  get 'random', to: 'main#random_redirect'
  get 'csv', to: 'main#download_csv', as: 'download_csv'
  get 'index.opml', to: 'main#download_opml', as: 'download_opml'
  get 'posts', to: 'posts#index'
  get 'posts/:id', to: 'posts#show', as: 'post'
  
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
    resources :blogs do
      member do
        patch :approve
        patch :reject
        post :refresh_posts
        post :check_status
        post :update_karma
      end
    end
    resources :posts, only: [:index, :show, :destroy]
  end
end

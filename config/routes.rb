Rails.application.routes.draw do
  root 'main#index'
  get 'random', to: 'main#random_redirect'
  get 'csv', to: 'main#download_csv', as: 'download_csv'
  get 'index.opml', to: 'main#download_opml', as: 'download_opml'
  resources :blogs, only: [:create]
end

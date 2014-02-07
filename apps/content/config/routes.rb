Content::Engine.routes.draw do
  resources :posts, only: [:index, :create]
end

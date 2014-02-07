Admin::Engine.routes.draw do
  scope "admin" do

    root to: 'home#index'
    get 'search/posts' => "home#post_search", as: 'post_search'
    get 'search/users' => "home#user_search", as: 'user_search'

    get  'login'  => 'login#new'
    post 'login'  => 'login#create', as: 'logout'
    get  'logout' => 'login#destroy'

    resources :users, only: [:show, :edit, :update] do
      member do
        get :posts
      end
    end

    resources :posts, only: [:show, :edit, :update]
  end
end

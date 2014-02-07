Account::Engine.routes.draw do
  get  'signup' => 'users#new'
  post 'signup' => 'users#create'

  get  'login'  => 'login#new'
  post 'login'  => 'login#create'
  get  'logout' => 'login#destroy'
end

Anotherapp::Application.routes.draw do
  authenticated :user do
    root :to => 'home#index'
  end
  root :to => "home#index"
  devise_for :users
  resources :users
  get 'pix/:id' => 'pix#lookup', :defaults => { :format => 'xml' }
end
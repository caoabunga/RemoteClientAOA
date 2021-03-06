Anotherapp::Application.routes.draw do
  get "drug/rurl"

  authenticated :user do
    root :to => 'home#index'
  end
  root :to => "home#index"
  devise_for :users
  resources :users
  get 'pix/:id' => 'pix#lookup', :defaults => { :format => 'xml' }
  post 'pix'  => 'pix#rurl', :defaults => { :format => 'xml' }
  post 'medication'  => 'medication#rurl', :defaults => { :format => 'xml' }
  post 'drug'  => 'drug#rurl', :defaults => { :format => 'xml' }
  post 'order'  => 'order#rurl', :defaults => { :format => 'xml' }
  get '/monitoring'   => "monitor#watch",       :as => :rx_monitoring
end
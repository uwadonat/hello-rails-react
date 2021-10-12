Rails.application.routes.draw do

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace 'api' do
    resources :messages
  end

  get '*page', to: 'pages#index', constraints: ->(req) do
    !req.xhr? && req.format.html?
  end

  root 'pages#index'
  
end

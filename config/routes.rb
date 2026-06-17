Rails.application.routes.draw do
  get "docs", to: "docs#show"
  get "openapi.yml", to: "docs#openapi"

  if Rails.env.development?
    mount PgHero::Engine, at: "/pghero"
    mount Blazer::Engine, at: "/blazer"
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount SolidErrors::Engine, at: "/solid_errors"
    mount FieldTest::Engine, at: "field_test"
    mount Flipper::UI.app(Flipper) => "/flipper"
  else
    authenticate :user, ->(user) { user.admin? } do
      mount PgHero::Engine, at: "/pghero"
      mount Blazer::Engine, at: "/blazer"
      mount MissionControl::Jobs::Engine, at: "/jobs"
      mount SolidErrors::Engine, at: "/solid_errors"
      mount FieldTest::Engine, at: "/field_test"
      mount Flipper::UI.app(Flipper) => "/flipper"
    end
  end

  mount_devise_token_auth_for "User", at: "auth", as: "token_auth_users"
  devise_for :users, only: [ :sessions ]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get "hello" => "hello#show"
      resources :users, only: [ :index, :show, :create, :update, :destroy ] do
        collection do
          get :me
        end
      end
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end

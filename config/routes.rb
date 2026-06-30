Rails.application.routes.draw do
  devise_for :admins, only: [ :sessions, :passwords ], controllers: {
    sessions: "admins/sessions",
    passwords: "admins/passwords"
  }

  if Rails.env.development?
    get "docs", to: "docs#show"
    get "openapi.yml", to: "docs#openapi"

    mount PgHero::Engine, at: "/pghero"
    mount Blazer::Engine, at: "/blazer"
    mount GoodJob::Engine, at: "/good_job"
    mount SolidErrors::Engine, at: "/solid_errors"
    mount FieldTest::Engine, at: "/field_test"
    mount Flipper::UI.app(Flipper) => "/flipper"
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Searchjoy::Engine, at: "/searchjoy"
    mount_avo
    get "admin/tools", to: "admin_tools#index", as: :admin_tools_dashboard
  else
    authenticate :admin do
      get "docs", to: "docs#show"
      get "openapi.yml", to: "docs#openapi"

      mount PgHero::Engine, at: "/pghero"
      mount Blazer::Engine, at: "/blazer"
      mount GoodJob::Engine, at: "/good_job"
      mount SolidErrors::Engine, at: "/solid_errors"
      mount FieldTest::Engine, at: "/field_test"
      mount Flipper::UI.app(Flipper) => "/flipper"
      mount Searchjoy::Engine, at: "/searchjoy"
      mount_avo
      get "admin/tools", to: "admin_tools#index", as: :admin_tools_dashboard
    end
  end

  mount_devise_token_auth_for "User", at: "auth", controllers: {
    registrations: "auth/registrations",
    sessions: "auth/sessions",
    passwords: "auth/passwords"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
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

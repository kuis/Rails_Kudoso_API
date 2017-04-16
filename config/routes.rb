Rails.application.routes.draw do



  apipie
  resources :avatars
  resources :partners
  resources :contacts

  resources :tickets

  resources :notes

  resources :activity_types

  resources :charges

  resources :content_ratings

  resources :contents

  resources :content_descriptors

  resources :content_types

  resources :activity_templates

  resources :todo_templates
  resources :themes



  devise_for :users, :controllers => { :sessions => "users/sessions" }

  resources :families do
    resources :devices
      member do
      devise_for :members, class: 'Member', :controllers => { :sessions => "members/sessions" }
    end
    resources :members do
      resources :activities do
        resources :activity_details
      end
      resources :my_todos
      resources :screen_times
      resources :st_overrides
      resources :screen_time_schedules
      member do
        post '/todo_groups/:todo_group_id/assign', to: "members#assign_todo_group"
        post '/todo_templates/assign', to: "members#assign_todo_templates"
      end
    end



    resources :todos do
      resources :todo_schedules do
        resources :members do
          resources :activities do
            resources :activity_details
          end
          resources :my_todos
          resources :screen_times
        end
      end
    end
  end

  namespace :admin do
    resources :activity_templates
    resources :activity_template_device_types
    resources :activity_types
    resources :api_devices
    resources :apps
    resources :avatars
    resources :contacts
    resources :families
    resources :todo_templates
    resources :devices
    resources :device_types
    resources :todo_templates
    resources :tickets
    resources :plugs
    resources :router_firmwares
    resources :router_models
    resources :routers
    resources :themes
    resources :users
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      resources :avatars
      resources :device_types
      resources :themes
      resources :sessions
      resources :plugs
      resources :routers do
        member do
          get :devices
          post :device
        end
      end
      resources :users do
        collection do
          post :reset_password
        end
      end
      resources :todo_templates
      resources :families do
        resources :activity_templates, only: [:index, :show]
        resources :todos do
          resources :todo_schedules do
            resources :schedule_rrules
          end
        end
        resources :devices do
          resources :apps_devices, path: :apps
          resources :members do
            resources :apps_members, path: :apps
          end
        end
        resources :members do
          resources :activities
          resources :apps_members, path: :apps
          resources :ledger, only: :index
          resources :my_todos do
            member do
              post :verify
            end
          end
          resources :todo_templates do
            member do
              post :assign
              delete :unassign
            end
          end
          member do
            post :buy_screen_time
          end
        end
      end
      resources :timezones
      post "/devices/:uuid/deviceDidRegister", to: 'devices#deviceDidRegister'
      patch "/devices/:udid/status", to: 'devices#status'
      post "/devices/record", to: 'devices#record'
      post "/devices/:id/apps", to: 'devices#post_apps'
      post "/devices/:id/apps/log", to: 'devices#post_applog'
      get "/devices/:id/apps", to: 'devices#get_apps'
    end
  end


  mount Stripe::Engine => "/stripe"
  get 'cities/:state', to: 'application#cities'
  get 'tos', to: 'home#tos'
  get 'privacy', to: 'home#privacy'
  get 'contact_us', to: 'home#contact_us'
  get 'support', to: 'home#support'
  get 'newsletter', to: 'home#newsletter'
  get 'privacy', to: 'home#privacy'
  get 'limit', to: 'home#limit'
  get 'protect', to: 'home#protect'
  get 'teach', to: 'home#teach'
  get 'reward', to: 'home#reward'
  get 'founders_circle', to: 'home#founders_circle'
  get 'founders_cirlce', to: 'home#founders_circle'
  get 'wizard', to: 'wizard#index'
  put 'wizard', to: 'wizard#update'
  post 'wizard', to: 'wizard#create'
  root to: 'home#index'

  match "*path", to: "errors#catch_404", via: :all

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

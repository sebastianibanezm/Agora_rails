Rails.application.routes.draw do
  mount Avo::Engine, at: Avo.configuration.root_path

  # Global routes — no org context
  resources :passwords, param: :token

  # Standalone admin login (no org scope)
  get    "admin/login", to: "sessions#new",     as: :new_admin_login
  post   "admin/login", to: "sessions#create",  as: :admin_login
  delete "admin/login", to: "sessions#destroy", as: :destroy_admin_login

  # Org-scoped routes
  scope "/:org_slug" do
    get    "login", to: "sessions#new",     as: :new_login
    post   "login", to: "sessions#create",  as: :login
    delete "login", to: "sessions#destroy", as: :destroy_login
    resources :shipments, only: %i[index show] do
      post :validate_source_of_truth, on: :member
    end
    resources :shipment_documents, only: %i[update] do
      post :approve, on: :member
      post :waive, on: :member
    end
    root "dashboard#index", as: :org_root
  end

  get "up" => "rails/health#show", as: :rails_health_check
end

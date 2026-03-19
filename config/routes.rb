Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Admin login
  get    "admin/login",  to: "admin/sessions#new",     as: :admin_login
  post   "admin/login",  to: "admin/sessions#create"
  delete "admin/logout", to: "admin/sessions#destroy",  as: :admin_logout

  # Admin namespace
  namespace :admin do
    root to: "ag_sessions#index"

    resources :ag_sessions do
      member do
        patch :open
        patch :close
      end
      resources :participants, only: %i[create destroy] do
        member { patch :unclaim }
      end
      resources :questions do
        member do
          patch :activate
          patch :close
        end
      end
    end
  end

  # Identification page (shared link for the whole session)
  get  "ag/:session_token",       to: "identification#show",  as: :identification
  post "ag/:session_token/claim", to: "identification#claim", as: :identification_claim

  # Participant voting surface
  get  "vote/:session_token/:participant_token",        to: "voting#show",   as: :voting
  post "vote/:session_token/:participant_token",        to: "voting#create", as: :voting_submit
  get  "vote/:session_token/:participant_token/area",   to: "voting#area",   as: :voting_area

  root to: "admin/sessions#new"
end

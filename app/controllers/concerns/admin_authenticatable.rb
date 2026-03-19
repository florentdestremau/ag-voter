module AdminAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
  end

  private

  def require_admin
    unless session[:admin_authenticated]
      redirect_to admin_login_path, alert: "Accès réservé à l'administrateur."
    end
  end
end

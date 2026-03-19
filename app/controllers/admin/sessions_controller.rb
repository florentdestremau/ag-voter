class Admin::SessionsController < ApplicationController
  def new; end

  def create
    expected = ENV.fetch("ADMIN_TOKEN", "admin-secret")
    if params[:token] == expected
      session[:admin_authenticated] = true
      redirect_to admin_root_path, notice: "Connecté."
    else
      flash.now[:alert] = "Token invalide."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:admin_authenticated)
    redirect_to admin_login_path
  end
end

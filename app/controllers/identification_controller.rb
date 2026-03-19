class IdentificationController < ApplicationController
  before_action :find_session

  def show
    @participants = @ag_session.participants.order(:name)
  end

  def claim
    @participant = @ag_session.participants.find_by!(id: params[:participant_id])

    if @participant.claimed?
      @participants = @ag_session.participants.order(:name)
      flash.now[:alert] = "#{@participant.name} a déjà rejoint la session."
      render :show, status: :unprocessable_entity
      return
    end

    @participant.claim!
    redirect_to voting_path(@ag_session.token, @participant.token),
                notice: "Bienvenue, #{@participant.name} !"
  rescue ActiveRecord::RecordNotFound
    render plain: "Lien invalide.", status: :not_found
  end

  private

  def find_session
    @ag_session = AgSession.find_by!(token: params[:session_token])
    if @ag_session.closed?
      render plain: "Cette session est terminée.", status: :gone
    end
  rescue ActiveRecord::RecordNotFound
    render plain: "Session introuvable.", status: :not_found
  end
end

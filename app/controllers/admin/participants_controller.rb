class Admin::ParticipantsController < Admin::BaseController
  before_action :set_ag_session

  def create
    @participant = @ag_session.participants.build(participant_params)
    if @participant.save
      redirect_to admin_ag_session_path(@ag_session), notice: "Participant ajouté."
    else
      @participants = @ag_session.participants.order(:name)
      @questions = @ag_session.questions
      @new_participant = @participant
      @new_question = Question.new(ag_session: @ag_session)
      render "admin/ag_sessions/show", status: :unprocessable_entity
    end
  end

  def unclaim
    @participant = @ag_session.participants.find(params[:id])
    @participant.update!(claimed_at: nil, token: SecureRandom.urlsafe_base64(12))
    redirect_to admin_ag_session_path(@ag_session), notice: "#{@participant.name} peut s'identifier à nouveau."
  end

  def destroy
    @participant = @ag_session.participants.find(params[:id])
    @participant.destroy
    redirect_to admin_ag_session_path(@ag_session), notice: "Participant supprimé."
  end

  private

  def set_ag_session
    @ag_session = AgSession.find(params[:ag_session_id])
  end

  def participant_params
    params.expect(participant: [ :name ])
  end
end

class Admin::AgSessionsController < Admin::BaseController
  before_action :set_ag_session, only: %i[show edit update destroy open close]

  def index
    @ag_sessions = AgSession.order(created_at: :desc)
  end

  def show
    @participants = @ag_session.participants.order(:name)
    @questions = @ag_session.questions.to_a
    @new_participant = Participant.new(ag_session: @ag_session)
    @new_question = Question.new(ag_session: @ag_session)
  end

  def new
    @ag_session = AgSession.new
  end

  def create
    @ag_session = AgSession.new(ag_session_params)
    if @ag_session.save
      redirect_to admin_ag_session_path(@ag_session), notice: "Session créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @ag_session.update(ag_session_params)
      redirect_to admin_ag_session_path(@ag_session), notice: "Session mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def open
    @ag_session.update!(status: :active)
    redirect_to admin_ag_session_path(@ag_session), notice: "Session ouverte."
  end

  def close
    @ag_session.update!(status: :closed)
    redirect_to admin_ag_session_path(@ag_session), notice: "Session clôturée."
  end

  def destroy
    @ag_session.destroy
    redirect_to admin_ag_sessions_path, notice: "Session supprimée."
  end

  private

  def set_ag_session
    @ag_session = AgSession.find(params[:id])
  end

  def ag_session_params
    params.expect(ag_session: [ :name ])
  end
end

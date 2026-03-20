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
    broadcast_session_started
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

  def broadcast_session_started
    @ag_session.participants.each do |participant|
      Turbo::StreamsChannel.broadcast_replace_to(
        "session_status_#{@ag_session.id}",
        target: "waiting_room",
        partial: "voting/voting_area",
        locals: {
          active_question: @ag_session.active_question,
          already_voted: false,
          closed_questions: @ag_session.questions.closed.order(:position),
          session: @ag_session,
          participant: participant
        }
      )
    end
  end
end

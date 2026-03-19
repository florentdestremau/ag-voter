class Admin::QuestionsController < Admin::BaseController
  before_action :set_ag_session
  before_action :set_question, only: %i[edit update destroy activate close]

  def new
    @question = @ag_session.questions.build
    @question.choices.build
  end

  def create
    @question = @ag_session.questions.build(question_params)
    @question.position = @ag_session.questions.maximum(:position).to_i + 1
    if @question.save
      redirect_to admin_ag_session_path(@ag_session), notice: "Question créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @question.update(question_params)
      redirect_to admin_ag_session_path(@ag_session), notice: "Question mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to admin_ag_session_path(@ag_session), notice: "Question supprimée."
  end

  def activate
    @ag_session.questions.active.each(&:closed!)
    @question.active!
    broadcast_voting_area
    redirect_to admin_ag_session_path(@ag_session), notice: "Question activée."
  end

  def close
    @question.closed!
    broadcast_voting_area
    redirect_to admin_ag_session_path(@ag_session), notice: "Vote clôturé."
  end

  private

  def set_ag_session
    @ag_session = AgSession.find(params[:ag_session_id])
  end

  def set_question
    @question = @ag_session.questions.find(params[:id])
  end

  def question_params
    params.expect(question: [ :text, :position, choices_attributes: [ %i[id text is_other _destroy] ] ])
  end

  def broadcast_voting_area
    active_question = @ag_session.active_question
    closed_questions = @ag_session.questions.closed.order(:position)
    @ag_session.participants.each do |participant|
      already_voted = active_question && participant.voted_on?(active_question)
      Turbo::StreamsChannel.broadcast_replace_to(
        "voting_#{participant.token}",
        target: "voting_area",
        partial: "voting/voting_area",
        locals: { active_question:, already_voted:, closed_questions:, session: @ag_session, participant: }
      )
    end
  end
end

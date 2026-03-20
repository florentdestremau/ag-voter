class VotingController < ApplicationController
  before_action :find_participant_and_session

  def show
    @active_question = @ag_session.active_question
    @closed_questions = @ag_session.questions.closed.order(:position)
    @already_voted = @active_question && @participant.voted_on?(@active_question)
  end

  def create
    @active_question = @ag_session.active_question

    unless @active_question
      return redirect_to voting_path(@ag_session.token, @participant.token)
    end

    if @participant.voted_on?(@active_question)
      return redirect_to voting_path(@ag_session.token, @participant.token)
    end

    @vote = Vote.new(
      participant: @participant,
      question: @active_question,
      choice_id: vote_params[:choice_id],
      free_text: vote_params[:free_text]
    )

    if @vote.save
      broadcast_vote_count
      redirect_to voting_path(@ag_session.token, @participant.token)
    else
      @already_voted = false
      @closed_questions = @ag_session.questions.closed.order(:position)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def broadcast_vote_count
    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_session_#{@ag_session.id}",
      target: "question_#{@active_question.id}_vote_count",
      partial: "admin/questions/vote_count",
      locals: { question: @active_question }
    )
  end

  def find_participant_and_session
    @ag_session = AgSession.find_by!(token: params[:session_token])
    @participant = @ag_session.participants.find_by!(token: params[:participant_token])
    @participant.claim! unless @participant.claimed?
  rescue ActiveRecord::RecordNotFound
    render plain: "Lien invalide.", status: :not_found
  end

  def vote_params
    params.expect(vote: [ :choice_id, :free_text ])
  end
end

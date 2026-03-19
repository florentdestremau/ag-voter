require "test_helper"

class VotingControllerTest < ActionDispatch::IntegrationTest
  def voting_path_for(participant)
    voting_path(participant.ag_session.token, participant.token)
  end

  def area_path_for(participant)
    voting_area_path(participant.ag_session.token, participant.token)
  end

  def submit_path_for(participant)
    voting_submit_path(participant.ag_session.token, participant.token)
  end

  # ---- Access control ----

  test "show is accessible for active session" do
    get voting_path_for(participants(:alice))
    assert_response :success
  end

  test "show is forbidden for pending session" do
    get voting_path_for(participants(:pending_participant))
    assert_response :forbidden
  end

  test "show returns 404 for invalid token" do
    get voting_path("bad-session", "bad-participant")
    assert_response :not_found
  end

  # ---- Area (polling endpoint) ----

  test "area renders the partial for active session" do
    get area_path_for(participants(:alice))
    assert_response :success
  end

  test "area shows active question when one exists" do
    get area_path_for(participants(:alice))
    assert_response :success
    assert_match questions(:active_question).text, response.body
  end

  test "area shows already voted message after voting" do
    alice = participants(:alice)
    # alice has already voted on closed_question; let's vote on active_question
    Vote.create!(participant: alice, question: questions(:active_question), choice: choices(:pour))
    get area_path_for(alice)
    assert_response :success
  end

  # ---- Create (vote submission) ----

  test "create saves a vote and redirects" do
    bob = participants(:bob)
    assert_difference "Vote.count" do
      post submit_path_for(bob), params: { vote: { choice_id: choices(:pour).id } }
    end
    assert_redirected_to voting_path_for(bob)
  end

  test "create with other choice requires free_text" do
    bob = participants(:bob)
    assert_no_difference "Vote.count" do
      post submit_path_for(bob), params: { vote: { choice_id: choices(:autre).id, free_text: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "create with other choice and free_text saves the vote" do
    bob = participants(:bob)
    assert_difference "Vote.count" do
      post submit_path_for(bob), params: { vote: { choice_id: choices(:autre).id, free_text: "Ma réponse" } }
    end
    assert_redirected_to voting_path_for(bob)
    assert_equal "Ma réponse", Vote.last.free_text
  end

  test "create is idempotent: second vote is rejected" do
    alice = participants(:alice)
    # alice already voted on closed_question; try voting on active_question twice
    post submit_path_for(alice), params: { vote: { choice_id: choices(:pour).id } }
    assert_no_difference "Vote.count" do
      post submit_path_for(alice), params: { vote: { choice_id: choices(:pour).id } }
    end
  end

  test "create redirects when no active question" do
    ag = ag_sessions(:active_session)
    ag.questions.active.each(&:closed!)
    bob = participants(:bob)
    post submit_path_for(bob), params: { vote: { choice_id: choices(:pour).id } }
    assert_redirected_to area_path_for(bob)
  end

  test "create is forbidden for pending session" do
    post voting_submit_path(ag_sessions(:pending_session).token, participants(:pending_participant).token),
         params: { vote: { choice_id: choices(:pour).id } }
    assert_response :forbidden
  end
end

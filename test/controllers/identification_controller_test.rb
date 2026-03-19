require "test_helper"

class IdentificationControllerTest < ActionDispatch::IntegrationTest
  test "show renders participant list for active session" do
    get identification_path(ag_sessions(:active_session).token)
    assert_response :success
    assert_match participants(:alice).name, response.body
    assert_match participants(:bob).name, response.body
  end

  test "show renders participant list for pending session" do
    get identification_path(ag_sessions(:pending_session).token)
    assert_response :success
  end

  test "show returns 410 for closed session" do
    get identification_path(ag_sessions(:closed_session).token)
    assert_response :gone
  end

  test "show returns 404 for unknown token" do
    get identification_path("nope")
    assert_response :not_found
  end

  test "claim marks participant as claimed and redirects to voting page" do
    bob = participants(:bob)
    assert_not bob.claimed?

    post identification_claim_path(ag_sessions(:active_session).token),
         params: { participant_id: bob.id }

    assert_redirected_to voting_path(ag_sessions(:active_session).token, bob.token)
    assert bob.reload.claimed?
  end

  test "claim on already claimed participant re-renders the page with alert" do
    alice = participants(:alice)
    alice.claim!

    post identification_claim_path(ag_sessions(:active_session).token),
         params: { participant_id: alice.id }

    assert_response :unprocessable_entity
    assert_match alice.name, response.body
  end

  test "claim returns 404 for unknown participant id" do
    post identification_claim_path(ag_sessions(:active_session).token),
         params: { participant_id: 0 }
    assert_response :not_found
  end
end

class Admin::ParticipantsUnclaimTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "unclaim clears claimed_at and regenerates token" do
    alice = participants(:alice)
    alice.claim!
    old_token = alice.token

    patch unclaim_admin_ag_session_participant_path(ag_sessions(:active_session), alice)

    assert_redirected_to admin_ag_session_path(ag_sessions(:active_session))
    alice.reload
    assert_not alice.claimed?
    assert_not_equal old_token, alice.token
  end
end

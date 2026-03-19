require "test_helper"

class Admin::AgSessionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "index lists sessions" do
    get admin_ag_sessions_path
    assert_response :success
  end

  test "redirects to login when not authenticated" do
    # new integration session, no sign_in_admin called
    new_session = open_session
    new_session.get admin_ag_sessions_path
    new_session.assert_redirected_to admin_login_path
  end

  test "show renders the session dashboard" do
    get admin_ag_session_path(ag_sessions(:active_session))
    assert_response :success
  end

  test "create persists a new session" do
    assert_difference "AgSession.count" do
      post admin_ag_sessions_path, params: { ag_session: { name: "Nouvelle AG" } }
    end
    assert_redirected_to admin_ag_session_path(AgSession.last)
  end

  test "create fails with blank name" do
    assert_no_difference "AgSession.count" do
      post admin_ag_sessions_path, params: { ag_session: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "update changes the session name" do
    ag = ag_sessions(:active_session)
    patch admin_ag_session_path(ag), params: { ag_session: { name: "Nouveau nom" } }
    assert_redirected_to admin_ag_session_path(ag)
    assert_equal "Nouveau nom", ag.reload.name
  end

  test "destroy deletes the session" do
    ag = ag_sessions(:closed_session)
    assert_difference "AgSession.count", -1 do
      delete admin_ag_session_path(ag)
    end
    assert_redirected_to admin_ag_sessions_path
  end

  test "open sets session to active" do
    ag = ag_sessions(:pending_session)
    patch open_admin_ag_session_path(ag)
    assert_redirected_to admin_ag_session_path(ag)
    assert ag.reload.active?
  end

  test "close sets session to closed" do
    ag = ag_sessions(:active_session)
    patch close_admin_ag_session_path(ag)
    assert_redirected_to admin_ag_session_path(ag)
    assert ag.reload.closed?
  end
end

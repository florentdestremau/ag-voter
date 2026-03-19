require "test_helper"

class AgSessionTest < ActiveSupport::TestCase
  test "token is generated before validation on create" do
    ag = AgSession.new(name: "Test AG")
    assert ag.valid?
    assert ag.token.present?
  end

  test "token is unique" do
    # Use a persisted record so before_validation :on => :create doesn't regenerate the token
    ag = ag_sessions(:active_session)
    ag.token = ag_sessions(:pending_session).token
    assert_not ag.valid?
    assert ag.errors[:token].any?
  end

  test "name is required" do
    ag = AgSession.new
    assert_not ag.valid?
    assert ag.errors[:name].any?
  end

  test "active_question returns the active question" do
    ag = ag_sessions(:active_session)
    assert_equal questions(:active_question), ag.active_question
  end

  test "active_question returns nil when no active question" do
    ag = ag_sessions(:closed_session)
    assert_nil ag.active_question
  end

  test "status transitions" do
    ag = ag_sessions(:pending_session)
    assert ag.pending?
    ag.active!
    assert ag.active?
    ag.closed!
    assert ag.closed?
  end
end

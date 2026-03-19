require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  test "token is generated before validation on create" do
    participant = Participant.new(name: "Test", ag_session: ag_sessions(:active_session))
    assert participant.valid?
    assert participant.token.present?
  end

  test "name is required" do
    participant = Participant.new(ag_session: ag_sessions(:active_session))
    assert_not participant.valid?
    assert participant.errors[:name].any?
  end

  test "voted_on? returns true when participant has voted" do
    alice = participants(:alice)
    assert alice.voted_on?(questions(:closed_question))
  end

  test "voted_on? returns false when participant has not voted" do
    alice = participants(:alice)
    assert_not alice.voted_on?(questions(:active_question))
  end

  test "claimed? returns false by default" do
    assert_not participants(:bob).claimed?
  end

  test "claim! sets claimed_at" do
    bob = participants(:bob)
    bob.claim!
    assert bob.claimed?
    assert_not_nil bob.claimed_at
  end
end

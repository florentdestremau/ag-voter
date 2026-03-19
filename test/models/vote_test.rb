require "test_helper"

class VoteTest < ActiveSupport::TestCase
  def valid_vote(overrides = {})
    Vote.new({
      participant: participants(:bob),
      question: questions(:active_question),
      choice: choices(:pour)
    }.merge(overrides))
  end

  test "valid with regular choice" do
    assert valid_vote.valid?
  end

  test "requires free_text when choice is_other" do
    vote = valid_vote(choice: choices(:autre), free_text: "")
    assert_not vote.valid?
    assert vote.errors[:free_text].any?
  end

  test "valid with free_text when choice is_other" do
    vote = valid_vote(choice: choices(:autre), free_text: "Ma réponse")
    assert vote.valid?
  end

  test "prevents double vote on same question" do
    # alice already voted on closed_question via fixture
    duplicate = Vote.new(
      participant: participants(:alice),
      question: questions(:closed_question),
      choice: choices(:closed_contre)
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:participant_id].any?
  end

  test "rejects choice from another question" do
    other_choice = choices(:closed_pour) # belongs to closed_question
    vote = valid_vote(choice: other_choice)
    assert_not vote.valid?
    assert vote.errors[:choice].any?
  end
end

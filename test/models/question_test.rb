require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "text is required" do
    question = Question.new(ag_session: ag_sessions(:active_session))
    assert_not question.valid?
    assert question.errors[:text].any?
  end

  test "total_votes counts all votes for the question" do
    assert_equal 1, questions(:closed_question).total_votes
  end

  test "results returns count and percentage per choice" do
    question = questions(:closed_question)
    results = question.results
    pour_result = results.find { |r| r[:choice] == choices(:closed_pour) }
    assert_equal 1, pour_result[:count]
    assert_equal 100.0, pour_result[:percentage]
    contre_result = results.find { |r| r[:choice] == choices(:closed_contre) }
    assert_equal 0, contre_result[:count]
    assert_equal 0, contre_result[:percentage]
  end

  test "results returns zero percentages when no votes" do
    question = questions(:active_question)
    results = question.results
    assert results.all? { |r| r[:percentage] == 0 }
  end

  test "other_free_texts returns free text answers" do
    q = questions(:active_question)
    Vote.create!(participant: participants(:bob), question: q, choice: choices(:autre), free_text: "Ma suggestion")
    assert_includes q.other_free_texts, "Ma suggestion"
  end
end

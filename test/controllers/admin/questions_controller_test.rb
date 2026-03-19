require "test_helper"

class Admin::QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_admin
    @ag = ag_sessions(:active_session)
  end

  test "new renders the form" do
    get new_admin_ag_session_question_path(@ag)
    assert_response :success
  end

  test "create persists a new question with choices" do
    assert_difference "Question.count" do
      post admin_ag_session_questions_path(@ag), params: {
        question: {
          text: "Approuvez-vous ?",
          choices_attributes: {
            "0" => { text: "Pour", is_other: "0" },
            "1" => { text: "Contre", is_other: "0" }
          }
        }
      }
    end
    assert_redirected_to admin_ag_session_path(@ag)
    assert_equal 2, Question.last.choices.count
  end

  test "create fails with blank text" do
    assert_no_difference "Question.count" do
      post admin_ag_session_questions_path(@ag), params: { question: { text: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "update changes question text" do
    q = questions(:pending_question)
    patch admin_ag_session_question_path(@ag, q), params: { question: { text: "Texte modifié" } }
    assert_redirected_to admin_ag_session_path(@ag)
    assert_equal "Texte modifié", q.reload.text
  end

  test "destroy deletes the question" do
    q = questions(:pending_question)
    assert_difference "Question.count", -1 do
      delete admin_ag_session_question_path(@ag, q)
    end
    assert_redirected_to admin_ag_session_path(@ag)
  end

  test "activate sets question to active and closes previously active question" do
    previously_active = questions(:active_question)
    q = questions(:pending_question)
    patch activate_admin_ag_session_question_path(@ag, q)
    assert_redirected_to admin_ag_session_path(@ag)
    assert q.reload.active?
    assert previously_active.reload.closed?
  end

  test "close sets question to closed" do
    q = questions(:active_question)
    patch close_admin_ag_session_question_path(@ag, q)
    assert_redirected_to admin_ag_session_path(@ag)
    assert q.reload.closed?
  end
end

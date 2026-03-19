class Vote < ApplicationRecord
  belongs_to :participant
  belongs_to :question
  belongs_to :choice

  validates :participant_id, uniqueness: { scope: :question_id, message: "a déjà voté sur cette question" }
  validates :free_text, presence: true, if: -> { choice&.is_other? }
  validate :choice_belongs_to_question

  private

  def choice_belongs_to_question
    return unless choice && question
    unless choice.question_id == question_id
      errors.add(:choice, "n'appartient pas à cette question")
    end
  end
end

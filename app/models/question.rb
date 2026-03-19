class Question < ApplicationRecord
  belongs_to :ag_session
  has_many :choices, -> { order(:id) }, dependent: :destroy
  has_many :votes, dependent: :destroy

  enum :status, { pending: "pending", active: "active", closed: "closed" }

  accepts_nested_attributes_for :choices, reject_if: :all_blank, allow_destroy: true

  validates :text, presence: true

  def total_votes
    votes.count
  end

  def results
    choices.map do |choice|
      count = votes.where(choice_id: choice.id).count
      pct = total_votes.zero? ? 0 : (count * 100.0 / total_votes).round(1)
      { choice: choice, count: count, percentage: pct }
    end
  end

  def other_free_texts
    votes.where(choice: choices.where(is_other: true)).pluck(:free_text).compact.reject(&:blank?)
  end
end

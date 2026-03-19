class Participant < ApplicationRecord
  belongs_to :ag_session
  has_many :votes, dependent: :destroy

  before_validation :generate_token, on: :create

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true

  def voted_on?(question)
    votes.exists?(question_id: question.id)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(12)
  end
end

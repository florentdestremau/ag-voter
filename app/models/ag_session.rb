class AgSession < ApplicationRecord
  has_many :participants, dependent: :destroy
  has_many :questions, -> { order(:position) }, dependent: :destroy

  enum :status, { pending: "pending", active: "active", closed: "closed" }

  before_validation :generate_token, on: :create

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true

  def active_question
    questions.find_by(status: "active")
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(12)
  end
end

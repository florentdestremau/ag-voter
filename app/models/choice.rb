class Choice < ApplicationRecord
  belongs_to :question

  validates :text, presence: true

  scope :regular, -> { where(is_other: false) }
  scope :other, -> { where(is_other: true) }
end

class ExpenseItem < ApplicationRecord
  # Relations
  has_many :movements, dependent: :destroy

  # Validations
  validates :description, :color, presence: true, uniqueness: true
end

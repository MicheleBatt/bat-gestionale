class Count < ApplicationRecord
  # Relations
  has_many :movements, dependent: :destroy

  # Validations
  validates :name, uniqueness: true
end

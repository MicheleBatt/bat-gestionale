class Deadline < ApplicationRecord

  # Validations
  validates :description, :expired_at, :year, presence: true
  validates :description, :uniqueness => { scope: :year }

  # Callbacks
  before_validation { self.year = self.expired_at.year.to_i }
  before_validation { self.month = self.expired_at.month.to_i }
end

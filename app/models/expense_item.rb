class ExpenseItem < ApplicationRecord
  # Relations
  has_many :movements, dependent: :destroy

  # Validations
  validates :description, :color, presence: true, uniqueness: true

  # Callbacks
  before_validation { self.color = "##{self.color.to_s.gsub(' ', '').upcase}" unless self.color.to_s.include?('#') }
  before_save { self.color = self.color.to_s.gsub(' ', '').upcase if self.color }
  before_save { self.description = self.description.to_s.strip.capitalize if self.description }
end

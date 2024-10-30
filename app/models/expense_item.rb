class ExpenseItem < ApplicationRecord
  # Relations
  belongs_to :organization
  has_many :movements, dependent: :destroy

  # Validations
  validates :description, :color, presence: true
  validates :description, :uniqueness => { scope: :organization }
  validates :color, :uniqueness => { scope: :organization }

  # Callbacks
  before_validation { self.color = "##{self.color.to_s.gsub(' ', '').upcase}" if self.color.present? && !self.color.to_s.include?('#') }
  before_save { self.color = self.color.to_s.gsub(' ', '').upcase if self.color }
  before_save { self.description = self.description.to_s.strip.capitalize if self.description }


  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(description)
  end

  def self.ransackable_associations(auth_object = nil)
    %i[]
  end
end

class ExpenseItem < ApplicationRecord
  # Relations
  belongs_to :organization
  has_many :movements, dependent: :destroy

  # Validations
  validates :description, :color, presence: true
  validates :description, :uniqueness => { scope: :organization }
  validates :color, :uniqueness => { scope: :organization }

  # Callbacks
  before_validation { parse_color }
  before_validation { self.description = self.description.to_s.strip.capitalize if self.description }


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

  def parse_color
    if self.color.present?
      parsed_color = self.color.to_s.delete(' ').upcase
      parsed_color = "##{parsed_color}"  unless parsed_color.start_with?('#')
      self.color = parsed_color
    end
  end
end

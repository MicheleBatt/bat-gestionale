class Deadline < ApplicationRecord
  # Validations
  belongs_to :organization
  validates :description, :expired_at, :year, :month, presence: true
  validates :description, :uniqueness => { scope: :year }

  # Callbacks
  before_validation { self.year = self.expired_at.year.to_i if self.expired_at }
  before_validation { self.month = self.expired_at.month.to_i if self.expired_at }
  before_save { self.description = self.description.to_s.strip.capitalize if self.description }


  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(description year month)
  end

  def self.ransackable_associations(auth_object = nil)
    %i[]
  end
end

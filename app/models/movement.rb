include MovementsHelper
include ApplicationHelper

class Movement < ApplicationRecord
  # Relations
  belongs_to :count
  belongs_to :expense_item, optional: true

  # Validations
  validates :amount, :causal, :movement_type, :emitted_at, :year, :month, presence: true
  validate :valid_amount?
  validate :valid_expense_item_reference?
  enum movement_type: MOVEMENT_TYPES.index_by(&:itself), _prefix: :movement_type

  # Callbacks
  before_validation { self.amount = self.amount * -1 if self.movement_type == 'out' && self.amount > 0 }
  before_validation { self.year = self.emitted_at.year.to_i }
  before_validation { self.month = self.emitted_at.month.to_i }
  before_validation { self.year_month = date_to_integer(self.emitted_at.year, self.emitted_at.month) }


  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(movement_type expense_item_id emitted_at year month)
  end

  def self.ransackable_associations(auth_object = nil)
    %i[]
  end

  def valid_amount?
    if self.movement_type == 'out' && self.amount > 0
      errors.add(:amount, "must be negative")
    end
    if self.movement_type == 'in' && self.amount < 0
      errors.add(:amount, "must be positive")
    end
  end

  def valid_expense_item_reference?
    if self.movement_type == 'out' && self.expense_item_id.blank?
      errors.add(:expense_item_id, "must be present")
    end

    if self.movement_type == 'in' && self.expense_item_id.present?
      errors.add(:expense_item_id, "cannot be present")
    end
  end
end

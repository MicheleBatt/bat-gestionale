include MovementsHelper

class Movement < ApplicationRecord
  # Relations
  belongs_to :count
  belongs_to :expense_item, optional: true

  # Validations
  validates :amount, :causal, :movement_type, :emitted_at, :year, :month, presence: true
  validate :valid_expense_item_reference?
  enum movement_type: MOVEMENT_TYPES.index_by(&:itself), _prefix: :movement_type

  # Callbacks
  before_validation { self.year = self.emitted_at.year.to_i }
  before_validation { self.month = self.emitted_at.month.to_i }

  # Instance Methods
  def valid_expense_item_reference?
    if self.movement_type == 'out' && self.expense_item_id.blank?
      errors.add(:expense_item_id, "must be present")
    end

    if self.movement_type == 'in' && self.expense_item_id.present?
      errors.add(:expense_item_id, "cannot be present")
    end
  end
end

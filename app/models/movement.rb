include MovementsHelper
include ApplicationHelper

class Movement < ApplicationRecord
  # Relations
  belongs_to :count
  belongs_to :expense_item, optional: true

  # Validations
  validates :amount, :causal, :movement_type, :emitted_at, :year, :month, :day, :year_month_day, presence: true
  validate :valid_amount?
  validate :valid_expense_item_reference?
  enum movement_type: MOVEMENT_TYPES.index_by(&:itself), _prefix: :movement_type

  # Callbacks
  before_validation { self.amount = self.amount * -1 if self.movement_type == 'out' && self.amount.to_f > 0 }
  before_validation { self.year = self.emitted_at.year.to_i if self.emitted_at }
  before_validation { self.month = self.emitted_at.month.to_i if self.emitted_at }
  before_validation { self.day = self.emitted_at.day.to_i if self.emitted_at }
  before_validation { self.year_month_day = date_to_integer(self.emitted_at.year, self.emitted_at.month, self.emitted_at.day) if self.emitted_at }
  before_save { self.causal = self.causal.to_s.strip if self.causal }
  before_save { self.amount = self.amount.to_f.round(2) if self.amount }

  after_save { set_count_current_amount }
  after_update { set_count_current_amount }
  after_destroy { set_count_current_amount }


  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(causal movement_type expense_item_id emitted_at year month)
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
      errors.add(:expense_item_id, "Specifica una voce di spesa!")
    end

    if self.movement_type == 'in' && self.expense_item_id.present?
      errors.add(:expense_item_id, "La voce di spesa può essere selezionata solo per movimenti di cassa in uscita!")
    end
  end

  def set_count_current_amount
    count = self.count
    count.update!(current_amount: count.initial_amount + self.count.movements.sum(:amount))
  end
end

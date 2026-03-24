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
  validate :valid_metal_fields?
  validates :price_at_transaction, numericality: { greater_than_or_equal_to: 0.0 }, allow_nil: true
  enum movement_type: MOVEMENT_TYPES.index_by(&:itself), _prefix: :movement_type

  # Callbacks
  before_validation { self.amount = self.amount * -1 if self.movement_type == 'out' && self.amount.to_f > 0 }
  before_validation { self.year = self.emitted_at.year.to_i if self.emitted_at }
  before_validation { self.month = self.emitted_at.month.to_i if self.emitted_at }
  before_validation { self.day = self.emitted_at.day.to_i if self.emitted_at }
  before_validation { self.year_month_day = date_to_integer(self.emitted_at.year, self.emitted_at.month, self.emitted_at.day) if self.emitted_at }
  before_save { self.causal = self.causal.to_s.strip if self.causal }
  before_save { self.amount = self.amount.to_f.round(2) if self.amount }
  before_save { self.karat = self.karat.to_f.round(2) if self.karat }
  before_save { self.price_at_transaction = self.price_at_transaction.to_f.round(2) if self.price_at_transaction }

  after_save { self.count.set_current_amount }
  after_update { self.count.set_current_amount }
  after_destroy { self.count.set_current_amount }


  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(causal movement_type expense_item_id emitted_at year month count_id karat)
  end

  def self.ransackable_associations(auth_object = nil)
    %i[]
  end

  def valid_amount?
    if self.movement_type == 'out' && self.amount.to_f > 0
      errors.add(:amount, "must be negative")
    end
    if self.movement_type == 'in' && self.amount.to_f < 0
      errors.add(:amount, "must be positive")
    end
  end

  def valid_expense_item_reference?
    return if metal_account?

    if self.movement_type == 'out' && self.expense_item_id.blank?
      errors.add(:expense_item_id, "Specifica una voce di spesa!")
    end

    if self.movement_type == 'in' && self.expense_item_id.present?
      errors.add(:expense_item_id, "La voce di spesa può essere selezionata solo per movimenti di cassa in uscita!")
    end
  end

  def valid_metal_fields?
    if metal_account?
      errors.add(:karat, "can't be blank") if self.karat.blank?
      errors.add(:price_at_transaction, "can't be blank") if self.price_at_transaction.blank?
    end
  end

  def metal_account?
    self.count&.metal_account?
  end

  # Valore economico del movimento (grammi × prezzo/grammo)
  def economic_value
    return nil unless metal_account? && price_at_transaction.present?
    (amount.to_f.abs * price_at_transaction.to_f).round(2)
  end
end

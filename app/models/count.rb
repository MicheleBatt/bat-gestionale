class Count < ApplicationRecord
  include Rails.application.routes.url_helpers

  # Relations
  has_many :movements, dependent: :destroy
  has_many :expense_items, through: :movements

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :initial_amount, presence: true
  validates :ordering_number, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_save { self.description = self.description.to_s.strip if self.description }
  before_save { self.iban = self.name.to_s.gsub(' ', '') if self.iban }
  before_save { self.initial_amount = self.initial_amount.to_f.round(2) if self.initial_amount }
  before_save { self.current_amount = self.initial_amount.to_f.round(2) if self.current_amount }

  # Instance Methods
  def movements_path_by_month(year, month, format = :html)
    count_movements_path(count_id: self.id, q: { 'year_eq': year, 'month_eq': month }, format: format)
  end

  def movements_default_path(year = self.movements.maximum('year') || Time.now.year, month: self.movements.maximum('month') || Time.now.month)
    self.movements_path_by_month(year, month)
  end

  def stats_path_by_month(year)
    stats_count_path(id: self.id, q: { 'year_eq': year })
  end

  def stats_default_path(year = self.movements.maximum('year') || Time.now.year)
    self.stats_path_by_month(year)
  end

  def month_final_amount(year, month)
    self.initial_amount.to_f + self.movements.where('movements.year_month < ? ', date_to_integer(year, month)).sum(&:amount)
  end
end

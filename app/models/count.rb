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
  before_save { self.name = self.name.to_s.strip.capitalize if self.name }
  before_save { self.description = self.description.to_s.strip if self.description }
  before_save { self.iban = self.name.to_s.gsub(' ', '') if self.iban }
  before_save { self.initial_amount = self.initial_amount.to_f.round(2) if self.initial_amount }
  before_save { self.current_amount = self.initial_amount.to_f.round(2) if self.current_amount }

  # Instance Methods
  def path_by_month(year, month)
    count_movements_path(count_id: self.id, q: { 'year_eq': year, 'month_eq': month })
  end

  def default_path(year = Time.now.year, month: Time.now.month)
    self.path_by_month(Time.now.year, Time.now.month)
  end
end

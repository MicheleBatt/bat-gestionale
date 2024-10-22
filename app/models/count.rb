class Count < ApplicationRecord
  include Rails.application.routes.url_helpers

  # Relations
  has_many :movements, dependent: :destroy

  # Validations
  validates :name, uniqueness: true


  # Instance Methods
  def path_by_month(year, month)
    count_movements_path(count_id: self.id, q: { 'year_eq': year, 'month_eq': month })
  end

  def default_path(year = Time.now.year, month: Time.now.month)
    self.path_by_month(Time.now.year, Time.now.month)
  end
end

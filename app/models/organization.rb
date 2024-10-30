class Organization < ApplicationRecord
  include ApplicationHelper

  # Relations
  has_many :counts, -> { order(ordering_number: :asc) }, dependent: :destroy
  has_many :movements, through: :counts
  has_many :deadlines, dependent: :destroy
  has_many :expense_items, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  # Validations
  validates :name, presence: true, uniqueness: true

  # Callbacks
  before_save { self.name = self.name.to_s.strip if self.name }

  # Scopes
  scope :user, -> (user) {
    if user.present?
      joins(memberships: :user).where('lower(users.email) LIKE ?', "%#{user.to_s.downcase}%")
      .or(joins(memberships: :user).where('lower(users.first_name) LIKE ?', "%#{user.to_s.downcase}%"))
      .or(joins(memberships: :user).where('lower(users.last_name) LIKE ?', "%#{user.to_s.downcase}%"))
    end
  }

  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[user]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(name)
  end

  def self.ransackable_scopes_skip_sanitize_args
    %i[user count_search]
  end

  def self.ransackable_associations(auth_object = nil)
    %i[]
  end

  def min_year
    min_year_by(self)
  end

  def max_year
    max_year_by(self)
  end

  def years_range
    years_range_by(self)
  end

  def max_month
    max_month_by(self)
  end

  def initial_amount_by_date(year, month, day)
    initial_amount_by(self, year, month, day)
  end

  def get_current_amount(movements = self.movements)
    (self.counts.pluck(:initial_amount).sum.to_f + movements.sum(&:amount)).to_f.round(2)
  end
end

class Organization < ApplicationRecord
  include ApplicationHelper

  # Relations
  has_many :counts, -> { order(ordering_number: :asc) }, dependent: :destroy
  has_many :metal_accounts, -> { where(count_type: CountsHelper::METALS_COUNT_TYPES).order(ordering_number: :asc) }, class_name: 'Count', dependent: :destroy
  has_many :non_metal_accounts, -> { where.not(count_type: CountsHelper::METALS_COUNT_TYPES).order(ordering_number: :asc) }, class_name: 'Count', dependent: :destroy
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

  def initial_amount_by_date(year, month, day, karat = nil)
    initial_amount_by(self, year, month, day, karat)
  end

  def get_current_amount(movements = self.movements, date)
    amount = (self.non_metal_accounts.pluck(:initial_amount).sum.to_f + movements.where(karat: nil).sum(&:amount)).to_f.round(2)
    self.metal_accounts.all.each{ | count | amount += count.economic_value_at_date(date, movements.where(count_id: count.id)).to_f.round(2) }
    return amount.to_f.round(2)
  end

  def metal_account?
    false
  end

  def additional_stats_for_charts(year)
    movements_global_amount_by_counts = {}
    savings_global_amount_by_counts = {}

    self.counts.each do | count |
      if count.metal_account?
        if year.present?
          global_amount = count.economic_value_at_date(Date.new(year.to_i, 12, 31))
        else
          global_amount = count.economic_value_at_date(Date.new(count.max_year, 12, 31))
        end
      else
        if year.present?
          global_amount = count.initial_amount_by_date(year.to_i + 1, 1, 1)
        else
          global_amount = count.initial_amount_by_date(count.max_year + 1, 1, 1)
        end
      end
      movements_global_amount_by_counts[count.name] = global_amount
      savings_global_amount_by_counts[count.name] = global_amount if count.count_type != 'bank_account'
    end

    [
      movements_global_amount_by_counts,
      savings_global_amount_by_counts
    ]
  end
end

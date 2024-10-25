class Count < ApplicationRecord
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  # Relations
  has_many :movements, dependent: :destroy
  has_one :first_movement, -> { order(emitted_at: :asc, id: :asc) }, class_name: 'Movement', dependent: :destroy
  has_one :last_movement, -> { order(emitted_at: :desc, id: :desc) }, class_name: 'Movement', dependent: :destroy
  has_many :expense_items, through: :movements

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :initial_amount, presence: true
  validates :ordering_number, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_save { self.description = self.description.to_s.strip if self.description }
  before_save { self.iban = self.iban.to_s.gsub(' ', '') if self.iban }
  before_save { self.initial_amount = self.initial_amount.to_f.round(2) if self.initial_amount }
  before_save { self.current_amount = self.current_amount.to_f.round(2) if self.current_amount }


  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(name)
  end

  def self.ransackable_associations(auth_object = nil)
    %i[]
  end

  def min_year
    self.movements.minimum('year') || Time.now.year
  end

  def max_year
    self.movements.maximum('year') || Time.now.year
  end

  def years_range
    (self.min_year..self.max_year).to_a
  end

  def max_month
    self.movements.where(year: self.max_year).maximum('month') || Time.now.month
  end

  def movements_path_by_month(year, month = nil, format = :html)
    if month.present?
      count_movements_path(count_id: self.id, q: { 'emitted_at_gteq': "#{year}-#{month}-01", 'emitted_at_lteq': "#{year}-#{month}-#{Date.new(year.to_i, month.to_i, 1).end_of_month.day}" }, format: format)
    else
      count_movements_path(count_id: self.id, q: { 'emitted_at_gteq': "#{year}-01-01", 'emitted_at_lteq': "#{year}-12-31" }, format: format)
    end
  end

  def movements_default_path
    self.movements_path_by_month(self.max_year, self.max_month)
  end

  def stats_path_by_year(year)
    stats_count_path(id: self.id, q: { 'year_eq': year })
  end

  def stats_default_path(year = self.max_year)
    self.stats_path_by_year(year)
  end

  def initial_amount_by_date(year, month, day)
    (self.initial_amount.to_f + self.movements.where('movements.year_month_day < ? ', date_to_integer(year, month, day)).sum(&:amount)).to_f.round(2)
  end

  def first_movement_emission_date
    first_movement = self.first_movement
    first_movement&.emitted_at || Time.now.beginning_of_year
  end

  def last_movement_emission_date
    last_movement = self.last_movement
    last_movement&.emitted_at || Time.now.beginning_of_year
  end

  def fast_movements_list_links(year = nil, month = nil)
    if year.present?
      if month.nil?
        [
          self.movements_path_by_month(year.to_i - 1, nil),
          self.movements_path_by_month(year.to_i + 1, nil)
        ]
      else
        [
          self.movements_path_by_month(month.to_i == 1 ? year.to_i - 1 : year, month.to_i == 1 ? 12 : month.to_i - 1),
          self.movements_path_by_month(month.to_i == 12 ? year.to_i + 1 : year, month.to_i == 12 ? 1 : month.to_i + 1)
        ]
      end
    else
      []
    end
  end

  def movements_list_table_titles(year = nil, month = nil, from_date = nil, to_date = nil)
    table_title = "Rendiconto movimenti sul #{self.name}"
    total_amount_title = "Saldo complessivo"
    return { main_title: table_title, total_amount_title: "#{total_amount_title}:" } if year.blank? && month.blank? && from_date.blank? && to_date.blank?

    if year.present?
      if month.nil?
        {
          main_title: "#{table_title} nel #{year}",
          start_amount_title: "Fondo cassa a inizio anno:",
          total_amount_title: "#{total_amount_title} di fine anno:",
          final_amount_title: "Fondo cassa a fine anno:",
          xlsx_file_name: "#{year}.xlsx"
        }
      else
        {
          main_title: "#{table_title} - #{italian_month(month)} #{year}",
          start_amount_title: "Fondo cassa a inizio mese:",
          total_amount_title: "#{total_amount_title} di fine mese:",
          final_amount_title: "Fondo cassa a fine mese:",
          xlsx_file_name: "#{month} - #{italian_month(month)}.xlsx"
        }
      end
    else
      if from_date.present?
        splitted_from_date = from_date.split('-')
        from_italian_date = "#{splitted_from_date[2]} #{italian_month(splitted_from_date[1])} #{splitted_from_date[0]}"
      end
      if to_date.present?
        splitted_to_date = to_date.split('-')
        to_italian_date = "#{splitted_to_date[2]} #{italian_month(splitted_to_date[1])} #{splitted_to_date[0]}"
      end

      {
        main_title: "#{table_title}#{from_italian_date ? ' dal ' + from_italian_date : ''}#{to_italian_date ? ' al ' + to_italian_date : ''}",
        start_amount_title: "Fondo cassa#{from_italian_date ? ' al ' + from_italian_date : ''}:",
        total_amount_title: "#{total_amount_title}:",
        final_amount_title: "Fondo cassa#{to_italian_date ? ' al ' + to_italian_date : ''}:",
        xlsx_file_name: "Rendiconto movimenti.xlsx"
      }
    end
  end
end

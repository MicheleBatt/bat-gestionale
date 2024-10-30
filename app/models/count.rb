class Count < ApplicationRecord
  include ApplicationHelper
  include CountsHelper
  include Rails.application.routes.url_helpers

  # Relations
  belongs_to :organization
  has_many :movements, dependent: :destroy
  has_one :first_movement, -> { order(emitted_at: :asc, id: :asc) }, class_name: 'Movement', dependent: :destroy
  has_one :last_movement, -> { order(emitted_at: :desc, id: :desc) }, class_name: 'Movement', dependent: :destroy
  has_many :expense_items, through: :movements

  # Validations
  validates :name, :initial_amount, :count_type, presence: true
  validates :name, :uniqueness => { scope: :organization }
  validates :ordering_number, numericality: { greater_than_or_equal_to: 0 }
  enum monitoring_scope: MONITORING_SCOPES.index_by(&:itself), _prefix: :monitoring_scope
  enum count_type: ALL_COUNT_TYPES.keys.index_by(&:itself), _prefix: :count_type

  # Callbacks
  before_save { self.description = self.description.to_s.strip if self.description }
  before_save { self.iban = self.iban.to_s.gsub(' ', '') if self.iban }
  before_save { self.initial_amount = self.initial_amount.to_f.round(2) if self.initial_amount }
  before_save { self.current_amount = self.current_amount.to_f.round(2) if self.current_amount }
  after_save { set_current_amount }
  after_update { set_current_amount }


  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(name count_type)
  end

  def self.ransackable_associations(auth_object = nil)
    %i[]
  end

  def movements_path_by_month(year = nil, month = nil, format = :html)
    if year.present? && month.present?
      organization_count_movements_path(organization_id: self.organization_id, count_id: self.id, q: { 'emitted_at_gteq': "#{year}-#{month}-01", 'emitted_at_lteq': "#{year}-#{month}-#{Date.new(year.to_i, month.to_i, 1).end_of_month.day}" }, format: format)
    elsif year.present?
      organization_count_movements_path(organization_id: self.organization_id, count_id: self.id, q: { 'emitted_at_gteq': "#{year}-01-01", 'emitted_at_lteq': "#{year}-12-31" }, format: format)
    else
      organization_count_movements_path(organization_id: self.organization_id, count_id: self.id, format: format)
    end
  end

  def movements_default_path
    case self.monitoring_scope
    when 'monthly'
      self.movements_path_by_month(self.max_year, self.max_month)
    when 'annual'
      self.movements_path_by_month(self.max_year)
    else
      self.movements_path_by_month
    end
  end

  def stats_path_by_year(year = nil)
    if year.present?
      stats_organization_count_path(organization_id: self.organization_id, id: self.id, q: { 'year_eq': year })
    else
      stats_organization_count_path(organization_id: self.organization_id, id: self.id)
    end
  end

  def stats_default_path
    case self.monitoring_scope
    when 'monthly'
      self.stats_path_by_year(self.max_year)
    else
      self.stats_path_by_year
    end
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
          xlsx_file_name: "#{year}.xlsx",
          expense_items_amounts_chart: "Ammontare spese nel #{year}"
        }
      else
        {
          main_title: "#{table_title} - #{italian_month(month)} #{year}",
          start_amount_title: "Fondo cassa a inizio mese:",
          total_amount_title: "#{total_amount_title} di fine mese:",
          final_amount_title: "Fondo cassa a fine mese:",
          xlsx_file_name: "#{month} - #{italian_month(month)}.xlsx",
          expense_items_amounts_chart: "Ammontare spese #{italian_month(month)} #{year}"
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
        xlsx_file_name: "Rendiconto movimenti.xlsx",
        expense_items_amounts_chart: "Ammontare spese"
      }
    end
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
    (self.initial_amount.to_f + movements.sum(&:amount)).to_f.round(2)
  end

  def set_current_amount
    self.update_columns(current_amount: self.get_current_amount)
  end
end

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
  enum count_type: ALL_COUNT_TYPES.keys.map { | key | key.to_s }.index_by(&:itself), _prefix: :count_type
  enum currency: ALL_CURRENCIES.index_by(&:itself), _prefix: :count_type

  # Callbacks
  before_validation { set_currency }
  before_save { self.description = self.description.to_s.strip if self.description }
  before_save { self.iban = self.iban.to_s.gsub(' ', '') if self.iban }
  before_save { self.initial_amount = self.initial_amount.to_f.round(2) if self.initial_amount }
  before_save { self.current_amount = self.current_amount.to_f.round(2) if self.current_amount }
  after_save { set_current_amount }
  after_save { realign_ordering_numbers }


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

  def movements_default_path(year = self.max_year, month = self.max_month)
    case self.monitoring_scope
    when 'monthly'
      self.movements_path_by_month(year, month)
    when 'annual'
      self.movements_path_by_month(year)
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

  def initial_amount_by_date(year, month, day, karat = nil)
    initial_amount_by(self, year, month, day, karat)
  end

  def get_current_amount(movements = self.movements, date = nil)
    (self.initial_amount.to_f + movements.sum(&:amount)).to_f.round(2)
  end

  def set_currency
    self.currency = 'grams' if self.metal_account?
  end

  def metal_account?
    self.metal_type.present?
  end

  def unit
    case self.set_currency
    when 'grams'
      'g'
    else
      '€'
    end
  end

  # Tipo di metallo del conto (es. 'XAU', 'XAG')
  def metal_type
    ALL_METALS.keys.find { |key| self.count_type.start_with?(key.to_s.downcase) }.presence
  end

  # Metodo che calcola la giacenza (espressa in termini di grammi) per caratura
  def metal_holdings(movements = self.movements)
    return {} unless metal_account?
    movements.reorder('').group(:karat).sum(:amount).transform_values { |v| v.to_f.round(2) }
  end

  # Metodo che calcola i grammi totali nel piano
  def total_grams(movements = self.movements)
    return 0 unless metal_account?
    movements.reorder('').sum(:amount).to_f.round(2)
  end

  # Metodo che calcola il valore economico corrente del piano di accumulo su un metallo prezioso
  # (usa i valori correnti estratti da MetalValue)
  def current_economic_value(movements = self.movements)
    self.economic_value_at_date(Date.today, movements)
  end

  # Metodo che calcola il valore economico a una certa data del piano di accumulo su un metallo prezioso
  # (usa i valori storicizzati estratti da MetalValue)
  def economic_value_at_date(date, movements = self.movements)
    return nil unless metal_account?
    metal = metal_type
    return 0 if metal.blank?

    movements_at_date = movements.where('emitted_at <= ?', date)
    holdings = metal_holdings(movements_at_date)
    total = 0
    holdings.each do |karat, grams|
      price = MetalValue.price_at_date(metal, karat, date)
      total += grams.abs * price
    end
    total.round(2)
  end

  def set_current_amount
    self.update_columns(current_amount: self.get_current_amount)
  end

  def realign_ordering_numbers
    unless self.ordering_number.nil?
      counts = self.organization.counts.where.not(id: self.id)
      if counts.find_by(ordering_number: self.ordering_number).present?
        counts.where("ordering_number >= ?", self.ordering_number).update_all("ordering_number = ordering_number + 1")
      end
    end
  end

  def additional_stats_for_charts(params)
    metal_values_by_last_days = []
    final_valued_amounts_by_date = {}
    metal_values_by_date = []
    metal_values_by_karats = {}
    metal_values_by_karat = {}
    out_global_amounts = []
    in_global_amounts = []

    if self.metal_account?
      metal = self.metal_type
      karats = MetalValuesHelper::available_karats_for_select(metal)
      karats = karats.filter{ | k | k[1] == params[:q][:karat_eq].to_f } if params[:q].present? && params[:q][:karat_eq].present?
      karats_values = karats.map{ | k | k[1] }

      # Estraggo il valore di quel metallo per caratura negli ultimi 31 giorni
      date_format = "%-d %b"
      dates = ((Date.today - 30.days)..(Date.today)).to_a
      metal_values = MetalValue.where(metal: self.metal_type, recorded_at: dates).order(recorded_at: :asc)
      metal_values = metal_values.where(karat: karats_values )
      metal_values = metal_values.group_by(&:karat)
      dates = dates.map{ | date | parse_date(date, date_format) }

      metal_values.keys.each do | karat |
        metal_values[karat] = metal_values[karat].group_by{ | mv | parse_date(mv.recorded_at, date_format) }
        metal_values_by_karats[karat] ||= {}
        dates.each do | date |
          value = metal_values[karat][date]&.sort_by(&:value)&.last&.value
          metal_values_by_karats[karat][date] = value if value.present?
        end
      end

      metal_values_by_karats.keys.sort.reverse.each do |karat|
        metal_values_by_last_days << { name: "#{karat.to_s.gsub('.0', '')}k", data: metal_values_by_karats[karat] }
      end


      _, year, _, now, time_ranges = ApplicationHelper::time_scope(self, params)
      time_ranges.each do | time_range |
        break if year.present? && year.to_i >= now.year && time_range > now.month

        it_month = italian_month(time_range) if year.present?

        # Calcolo il valore della giacenza globale a fine di ogni mese / anno
        movements_by_karats = self.movements.where(karat: karats_values)
        if year.present?
          final_valued_amounts_by_date[it_month] = self.economic_value_at_date(Date.new(year.to_i, time_range, 1).end_of_month, movements_by_karats)
        else
          final_valued_amounts_by_date[time_range] = self.economic_value_at_date(Date.new(time_range, 12, 31), movements_by_karats)
        end


        karats.each do | karat |
          # Estraggo il valore di quel metallo per caratura a fine di ogni mese / anno
          metal_values_by_karat[karat] ||= {}
          if year.present?
            metal_values_by_karat[karat][it_month] = MetalValue.price_at_date(metal, karat, Date.new(year.to_i, time_range, 1).end_of_month)
          else
            metal_values_by_karat[karat][time_range] = MetalValue.price_at_date(metal, karat, Date.new(time_range, 12, 31))
          end
        end


        # Calcolo le entrate / uscite complessive ad ogni mese / anno
        if year.present?
          out_global_amounts << [it_month, movements.where(month: time_range, movement_type: 'out').sum(&:amount).to_f.round(2) * -1]
          in_global_amounts << [it_month, movements.where(month: time_range, movement_type: 'in').sum(&:amount).to_f.round(2)]
        else
          out_global_amounts << [time_range, movements.where(year: time_range, movement_type: 'out').sum(&:amount).to_f.round(2) * -1]
          in_global_amounts << [time_range, movements.where(year: time_range, movement_type: 'in').sum(&:amount).to_f.round(2)]
        end
      end


      in_out_global_amounts = [
        {
          name: "Uscite",
          data: out_global_amounts
        },
        {
          name: "Entrate",
          data: in_global_amounts
        }
      ]


      # Costruisco l'array multi-linea per il grafico dei valori del metallo per caratura
      metal_values_by_karat.each do |karat, data|
        metal_values_by_date << { name: "#{karat[0]}", data: data }
      end
    end


    # Grafico plus/minusvalenze: per ogni vendita, compara il prezzo di vendita
    # con il costo di acquisto della stessa grammatura e caratura al prezzo più basso effettuato nel passato.
    # Logica di calcolo delle plus/minusvalenze con approccio "pool FIFO per prezzo crescente": per ogni vendita (out),
    # si consuma dal pool di acquisti della stessa caratura partendo dal prezzo al grammo più basso,
    # comparando costo d'acquisto vs ricavo di vendita.
    capital_gains_data = []
    if self.metal_account?
      out_movements = self.movements.where(movement_type: 'out').where(karat: karats_values).order(emitted_at: :asc)
      if out_movements.present?
        # Costruisco un pool di grammi acquistati per caratura, ordinati per prezzo al grammo crescente
        in_movements = self.movements.where(movement_type: 'in').where(karat: karats_values).order(price_per_gram_at_transaction: :asc, emitted_at: :asc)
        purchase_pool = {}
        in_movements.each do |m|
          karat = m.karat
          purchase_pool[karat] ||= []
          purchase_pool[karat] << { remaining_grams: m.amount.to_f.abs, ppg: m.price_per_gram_at_transaction.to_f }
        end

        out_movements.each do |sale|
          sale_grams = sale.amount.to_f.abs
          sale_ppg = sale.price_per_gram_at_transaction.to_f
          sale_total = (sale_grams * sale_ppg).round(2)
          karat = sale.karat
          pool = purchase_pool[karat] || []

          # Calcolo il costo di acquisto consumando dal pool (prezzo più basso prima)
          grams_to_match = sale_grams
          purchase_cost = 0.0
          pool.each do |slot|
            next if slot[:remaining_grams] <= 0 || grams_to_match <= 0
            take = [slot[:remaining_grams], grams_to_match].min
            purchase_cost += take * slot[:ppg]
            slot[:remaining_grams] -= take
            grams_to_match -= take
          end
          purchase_cost = purchase_cost.round(2)

          gain_pct = purchase_cost > 0 ? (((sale_total - purchase_cost) / purchase_cost) * 100).round(2) : 0.0
          gain_pct_str = gain_pct >= 0 ? "+#{gain_pct}%" : "#{gain_pct}%"
          label = "#{parse_date(sale.emitted_at, '%d/%m/%y')} #{sale.karat.to_i}k #{to_visible_amount(sale_grams, false)}g | plusvalenza: #{gain_pct_str}"
          capital_gains_data << { label: label, sale_total: sale_total, purchase_cost: purchase_cost, emitted_at: sale.emitted_at }
        end
      end

      # Filtro per time range: se è impostato un anno di visibilità, mostro solo le vendite di quell'anno
      if year.present?
        capital_gains_data = capital_gains_data.select { |d| d[:emitted_at].year == year.to_i }
      end
      capital_gains_data.each { |d| d.delete(:emitted_at) }
    end

    [
      final_valued_amounts_by_date,
      metal_values_by_last_days,
      metal_values_by_date,
      year,
      in_out_global_amounts,
      capital_gains_data
    ]
  end
end

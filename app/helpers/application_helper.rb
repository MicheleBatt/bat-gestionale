module ApplicationHelper

  include MetalValuesHelper

  DEFAULT_PAGE = 1.freeze
  DEFAULT_PER_PAGE_PARAM = 100.freeze

  ITALIAN_MONTHS = {
    1 => "Gennaio",
    2 => "Febbraio",
    3 => "Marzo",
    4 => "Aprile",
    5 => "Maggio",
    6 => "Giugno",
    7 => "Luglio",
    8 => "Agosto",
    9 => "Settembre",
    10 => "Ottobre",
    11 => "Novembre",
    12 => "Dicembre"
  }.freeze


  def italian_datetime(datetime)
    if datetime.present?
      datetime.in_time_zone('Europe/Rome')
    end
  end

  def parse_italian_datetime(datetime, format = '%a, %d %b %Y %H:%M:%S UTC %:z')
    if datetime.present?
      italian_datetime(datetime).strftime(format)
    end
  end

  def parse_date(datetime, format = '%d/%m/%Y - %k:%M:%S', italian_datetime = true)
    if datetime.present?
      if italian_datetime
        parse_italian_datetime(datetime, format)
      else
        datetime.strftime(format)
      end
    else
      nil
    end
  end

  def italian_month(number)
    ITALIAN_MONTHS[number.to_i] || "Numero non valido. Inserisci un numero da 1 a 12."
  end

  def italian_months_for_select
    [
      ["Gennaio", 1], ["Febraio", 2], ["Marzo", 3],
      ["Aprile", 4], ["Maggio", 5], ["Giugno", 6],
      ["Luglio", 7], ["Agosto", 8], ["Settembre", 9],
      ["Ottobre", 10], ["Novembre", 11], ["Dicembre", 12]
    ]
  end

  def to_visible_amount(amount, remove_minus = true)
    formatted_amount = amount
    formatted_amount = amount.to_s.gsub('-', '') if remove_minus
    formatted_amount = sprintf('%.2f', formatted_amount).gsub('.', ',')
    formatted_amount.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    formatted_amount
  end

  def date_to_integer(year, month, day)
    "#{year.to_i}#{month.to_i.to_s.rjust(2, '0')}#{day.to_i.to_s.rjust(2, '0')}".to_i
  end

  def stats_for_charts(entity, movements, params = nil, metal = nil)
    years_range = entity.years_range
    final_amounts_by_date = {}
    final_valued_amounts_by_date = {}
    metal_values_by_date = []
    metal_values_by_karat = {}
    movements_global_amount_by_expense_items = {}
    year = params[:q].present? ? params[:q][:year_eq] : nil
    months = (1..12).to_a
    if metal.present?
      karats = MetalValuesHelper::available_karats_for_select(metal)
      karats = karats.filter{ | k | k[1] == params[:q][:karat_eq].to_f } if params[:q].present? && params[:q][:karat_eq].present?
    end

    entity.expense_items.each_with_object({}) do |expense_item, hash|
      movements_global_amount_by_expense_items[expense_item] = {'total' => 0}
    end

    movements_max_amount = 0
    out_global_amounts = []
    in_global_amounts = []
    now = Time.now
    time_ranges = year.present? ? months : years_range
    time_ranges.each do | time_range |
      break if year.present? && year.to_i >= now.year && time_range > now.month

      it_month = italian_month(time_range) if year.present?

      # Calcolo la giacenza finale globale a fine di ogni mese / anno
      if valorize(entity, params)
        if year.present?
          final_amounts_by_date[it_month] = entity.economic_value_at_date(Date.new(year.to_i, time_range, 1).end_of_month)
        else
          final_amounts_by_date[time_range] = entity.economic_value_at_date(Date.new(time_range, 12, 31))
        end
      else
        if year.present?
          final_amounts_by_date[it_month] = entity.initial_amount_by_date(year, time_range + 1, 1, (params[:q] || {})[:karat_eq])
        else
          final_amounts_by_date[time_range] = entity.initial_amount_by_date(time_range + 1, 1, 1, (params[:q] || {})[:karat_eq])
        end
      end

      # Se l'entità corrente è un piano d'accumulo su un metallo prezioso
      if metal.present?
        # Calcolo il valore della giacenza globale a fine di ogni mese / anno
        movements_by_karats = entity.movements.where(karat: karats.map{ | k | k[1] })
        if year.present?
          final_valued_amounts_by_date[it_month] = entity.economic_value_at_date(Date.new(year.to_i, time_range, 1).end_of_month, movements_by_karats)
        else
          final_valued_amounts_by_date[time_range] = entity.economic_value_at_date(Date.new(time_range, 12, 31), movements_by_karats)
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
      end

      # Calcolo le uscite / entrate complessive ad ogni mese / anno
      if year.present?
        out_global_amounts << [it_month, movements.where(month: time_range, movement_type: 'out').sum(&:amount).to_f.round(2) * -1]
        in_global_amounts << [it_month, movements.where(month: time_range, movement_type: 'in').sum(&:amount).to_f.round(2)]
      else
        out_global_amounts << [time_range, movements.where(year: time_range, movement_type: 'out').sum(&:amount).to_f.round(2) * -1]
        in_global_amounts << [time_range, movements.where(year: time_range, movement_type: 'in').sum(&:amount).to_f.round(2)]
      end

      # Calcolo l'ammontare complessivo delle varie spese durante ogni mese / anno
      movements_global_amount_by_expense_items.keys.each do | expense_item |
        movements_by_expense_item = movements.where(movement_type: 'out', expense_item_id: expense_item.id)
        movements_by_expense_item = year.present? ? movements_by_expense_item.where(month: time_range) : movements_by_expense_item.where(year: time_range)
        global_amount_by_expense_items = movements_by_expense_item.sum(&:amount).to_f.round(2)
        global_amount_by_expense_items = global_amount_by_expense_items * -1 if global_amount_by_expense_items < 0
        movements_global_amount_by_expense_items[expense_item][year.present? ? it_month : time_range] = global_amount_by_expense_items
        movements_global_amount_by_expense_items[expense_item]['total'] = movements_global_amount_by_expense_items[expense_item]['total'] + global_amount_by_expense_items
        movements_max_amount = [movements_max_amount, global_amount_by_expense_items].max
      end
    end

    in_out_global_amounts = [
      {
        name: metal.present? ? "Vendite" : "Uscite",
        data: out_global_amounts
      },
      {
        name: metal.present? ? "Acquisti" : "Entrate",
        data: in_global_amounts
      }
    ]

    # Costruisco l'array multi-linea per il grafico dei valori del metallo per caratura
    metal_values_by_karat.each do |karat, data|
      metal_values_by_date << { name: "#{karat[0]}", data: data }
    end

    [
      years_range,
      final_amounts_by_date,
      final_valued_amounts_by_date,
      metal_values_by_date,
      movements_global_amount_by_expense_items,
      year,
      movements_max_amount,
      in_out_global_amounts
    ]
  end

  def min_year_by(entity)
    if entity.metal_account?
      [
        MetalValue.where(metal: entity.metal_type).minimum('recorded_at').year,
        entity.movements.minimum('year')
      ].compact.min || Time.now.year
    else
      entity.movements.minimum('year') || Time.now.year
    end
  end

  def max_year_by(entity)
    if entity.metal_account?
      [
        MetalValue.where(metal: entity.metal_type).maximum('recorded_at')&.year,
        entity.movements.maximum('year')
      ].compact.max || Time.now.year
    else
      entity.movements.maximum('year') || Time.now.year
    end
  end

  def years_range_by(entity)
    (entity.min_year..entity.max_year).to_a
  end

  def max_month_by(entity)
    if entity.metal_account?
      [
        MetalValue.where(metal: entity.metal_type).where("EXTRACT(YEAR FROM recorded_at) = ?", entity.max_year).maximum('recorded_at')&.month,
        entity.movements.where(year: entity.max_year).maximum('month')
      ].compact.max || Time.now.month
    else
      entity.movements.where(year: entity.max_year).maximum('month') || Time.now.month
    end
  end

  def initial_amount_by(entity, year, month, day, karat = nil)
    movements_by_date = entity.movements.where('movements.year_month_day < ? ', date_to_integer(year, month, day))
    movements_by_date = movements_by_date.where(karat: karat) if karat.present?
    entity.get_current_amount(movements_by_date, Date.new(year.to_i, month.to_i == 13 ? 12 : month.to_i, month.to_i == 13 ? 31 : day.to_i))
  end

    def valorize(entity, params)
      entity.is_a?(Count) && entity.metal_account? && params['controller'] == "organizations"
    end
end

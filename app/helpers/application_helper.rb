module ApplicationHelper

  DEFAULT_PAGE = 1.freeze
  DEFAULT_PER_PAGE_PARAM = 50.freeze

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
    "#{year.to_i}#{month.to_i.to_s.to_s.rjust(2, '0')}.split('-')#{day.to_i.to_s.to_s.rjust(2, '0')}".to_i
  end

  def stats_for_charts(entity, movements, params = nil)
    years_range = entity.years_range
    final_amounts_by_date = {}
    movements_global_amount_by_expense_items = {}
    year = params[:q].present? ? params[:q][:year_eq] : nil
    months = (1..12).to_a

    entity.expense_items.each_with_object({}) do |expense_item, hash|
      movements_global_amount_by_expense_items[expense_item] = {'total' => 0}
    end

    movements_max_amount = 0
    out_global_amounts = []
    in_global_amounts = []
    time_ranges = year.present? ? months : years_range
    time_ranges.each do | time_range |
      it_month = italian_month(time_range) if year.present?

      # Calcolo la giacenza finale globale a fine di ogni mese / anno
      if year.present?
        final_amounts_by_date[it_month] = entity.initial_amount_by_date(year, time_range + 1, 1)
      else
        final_amounts_by_date[time_range] = entity.initial_amount_by_date(time_range + 1, 1, 1)
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
        name: "Uscite",
        data: out_global_amounts
      },
      {
        name: "Entrate",
        data: in_global_amounts
      }
    ]


    [
      years_range,
      final_amounts_by_date,
      movements_global_amount_by_expense_items,
      year,
      movements_max_amount,
      in_out_global_amounts
    ]
  end

  def min_year_by(entity)
    entity.movements.minimum('year') || Time.now.year
  end

  def max_year_by(entity)
    entity.movements.maximum('year') || Time.now.year
  end

  def years_range_by(entity)
    (entity.min_year..entity.max_year).to_a
  end

  def max_month_by(entity)
    entity.movements.where(year: entity.max_year).maximum('month') || Time.now.month
  end

  def initial_amount_by(entity, year, month, day)
    movements_by_date = entity.movements.where('movements.year_month_day < ? ', date_to_integer(year, month, day))
    entity.get_current_amount(movements_by_date)
  end
end

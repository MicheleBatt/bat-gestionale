module ApplicationHelper

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

  def to_visible_amount(amount, remove_minus = true)
    formatted_amount = amount
    formatted_amount = amount.to_s.gsub('-', '') if remove_minus
    formatted_amount = sprintf('%.2f', formatted_amount).gsub('.', ',')
    formatted_amount.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\\1.')
    formatted_amount
  end

  def date_to_integer(year, month, day = nil)
    string_date = "#{year.to_i}#{month.to_i.to_s.to_s.rjust(2, '0')}"
    string_date = "#{string_date}#{day.to_i.to_s.to_s.rjust(2, '0')}" if day.present?
    string_date.to_i
  end
end

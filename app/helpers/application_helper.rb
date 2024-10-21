module ApplicationHelper


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
end

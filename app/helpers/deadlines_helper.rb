module DeadlinesHelper
  def upcoming_deadlines
    Deadline.where(year: Time.now.year, month: Time.now.month)
  end

  def upcoming_deadlines_count
    upcoming_deadlines.count
  end
end

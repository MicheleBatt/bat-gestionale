module DeadlinesHelper
  def upcoming_deadlines
    Deadline.where(month: Time.now.month)
  end

  def upcoming_deadlines_count
    upcoming_deadlines.count
  end
end

module DeadlinesHelper
  def upcoming_deadlines(organization)
    Deadline.where(organization_id: organization.id, year: Time.now.year, month: Time.now.month)
  end

  def upcoming_deadlines_count(organization)
    upcoming_deadlines(organization).count
  end
end

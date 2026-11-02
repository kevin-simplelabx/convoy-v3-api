class MaintenanceVisitDecorator < ApplicationDecorator
  # Upcoming, To Record (past, not recorded), Completed, Cancelled — the tabs of Fleet > Maintenance.
  def tab(today = Date.current)
    return "completed" if completed?
    return "cancelled" if cancelled?

    date < today ? "to_record" : "upcoming"
  end
end

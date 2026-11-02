module Occurrences
  # Runs that have ended and were not cancelled are completed (driver pay, invoices and reports count them).
  class Complete < ApplicationService
    def call = TripOccurrence.scheduled.where(ends_at: ..Time.current).update_all(status: "completed", updated_at: Time.current)
  end
end

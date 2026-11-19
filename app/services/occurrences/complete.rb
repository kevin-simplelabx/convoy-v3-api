module Occurrences
  # Runs that have ended and were not cancelled are completed (driver pay, invoices and reports count them).
  class Complete < ApplicationService
    # Returns how many; the runs' watchers and drivers hear about it (Realtime).
    def call
      scope = TripOccurrence.scheduled.where(ends_at: ..Time.current)
      runs = scope.pluck(:id, :date, :driver_id, :operator_driver_id).map { |id, date, d, o| { id:, date:, driver_id: d, operator_driver_id: o } }
      return 0 if runs.empty?

      count = scope.update_all(status: "completed", updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      Realtime.runs_changed(runs)
      count
    end
  end
end

# Stop Library membership: ask to add a school's stop (approved at once with the library permission, else pending for a
# library reviewer), and a reviewer's answer — Approve (every school sees it) or Keep for School.
module Stops
  module Library
    module_function

    def ask(stop, user)
      raise ApplicationService::Error, "#{stop.code} is already in the Stop Library" if stop.library_status == "approved"

      if user.can?(:library) then stop.update!(library_status: "approved", requested_by: user, requested_at: Time.current)
      else stop.update!(library_status: "pending", requested_by: user, requested_at: Time.current)
      end
      stop
    end

    def review(stop, status)
      raise ApplicationService::Error, "Answer Approve or Keep for School" unless %w[approved school].include?(status)
      raise ApplicationService::Error, "#{stop.code} is not waiting for approval" unless stop.library_status == "pending"

      stop.update!(library_status: status)
      stop
    end
  end
end

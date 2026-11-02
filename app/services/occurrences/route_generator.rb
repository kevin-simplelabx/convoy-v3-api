# What a School Bus route's runs should be between two dates: one run on every school day of its plan (the plan's
# weekdays, in use, not a public holiday or a day off on the school's calendar), at the route's times moved by the
# calendar (Late Arrival for AM, Early Dismissal for PM and CCA). The bus: changed by hand on the run > the route's
# replacement for the day (the regular bus becomes the ghost) > its regular bus that day; then Scheduler replacements.
module Occurrences
  class RouteGenerator < Generator
    def rows(route, from, to, existing: {})
      plan = route.plan
      school = plan.school
      first = [ from, plan.effective_from ].max
      last = [ to, plan.effective_to ].compact.min
      return [] if !plan.in_use || first > last

      replacement_index(first, last)
      (first..last).select { |d| school_day?(plan, school, d) }.flat_map do |date|
        replace(base_route_row(route, plan, school, date, existing[[ nil, route.id, date, nil, 1, 1 ]]), nil)
      end
    end

    private

    def school_day?(plan, school, date)
      @ctx.runs_on?(days: plan.days, skip_public_holidays: true, calendar_id: school.calendar_id, date:)
    end

    def base_route_row(route, plan, school, date, occ)
      shift = @ctx.time_shift(school.calendar_id, date, route.start_time, plan.calendar_session) + occ&.shift_minutes.to_i
      regular = route.regular_vehicle_id(date)
      moved = occ&.overridden?(:vehicle_id)
      route_rep = moved ? nil : route.replacement_on(date)
      vehicle_id = if moved then occ.vehicle_id
      elsif route_rep then route_rep.vehicle_id
      else regular
      end
      start_time = route.start_time + shift
      end_time = route.end_time + shift
      Row.new(
        trip_id: nil, school_route_id: route.id, date:, trip_run_id: nil, run_key: nil, slot_no: 1, part: 1,
        client_id: school.client_id, kind: "school_route", trip_label: route.title, start_time:, end_time:,
        starts_at: at(date, start_time), ends_at: at(date, end_time), shift_minutes: occ&.shift_minutes.to_i,
        pax: route.riders_count, price: 0, trip_value: 1, trip_assignment_id: nil, replacement_id: nil,
        original_vehicle_id: route_rep ? regular : nil, driver_name: nil, driver_phone: nil,
        **Occurrences.vehicle_attrs(@fleet, nil, vehicle_id, date)
      )
    end
  end
end

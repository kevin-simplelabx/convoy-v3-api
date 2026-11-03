# What a School Bus route's runs should be between two dates: one run on every school day of its plan — the plan's
# weekdays, in use, and a school day of the school's academic year (operating day, inside a term, not a holiday); with
# no academic year covering the date, Monday to Friday except public holidays (as Convoy OS). At the route's times
# (special days do not move them, as Convoy OS) plus a shift changed by hand on the run. The bus: changed by hand on
# the run > the route's replacement for the day (the regular bus becomes the ghost) > its regular bus that day; then
# Scheduler replacements.
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
      return false unless plan.days.include?(date.wday)

      year = academic_years(school.id).find { |y| date.between?(y.starts_on, y.ends_on) }
      year ? year.school_day?(date) : date.wday.between?(1, 5) && !@ctx.holiday?(date)
    end

    def academic_years(school_id)
      @academic_years ||= {}
      @academic_years[school_id] ||= AcademicYear.where(school_id:).includes(:terms, :holidays).to_a
    end

    # The regular bus's driver, when the route's replacement bus for the day comes with another driver.
    def original_driver(regular, date, minute, bus)
      was = Occurrences.vehicle_attrs(@fleet, nil, regular, date, minute).slice(:driver_id, :operator_driver_id)
      return {} if was.values.none? || was == bus.slice(:driver_id, :operator_driver_id)

      { original_driver_id: was[:driver_id], original_operator_driver_id: was[:operator_driver_id] }
    end

    def base_route_row(route, plan, school, date, occ)
      shift = occ&.shift_minutes.to_i
      regular = route.regular_vehicle_id(date)
      moved = occ&.overridden?(:vehicle_id)
      route_rep = moved ? nil : route.replacement_on(date)
      vehicle_id = if moved then occ.vehicle_id
      elsif route_rep then route_rep.vehicle_id
      else regular
      end
      start_time = route.start_time + shift
      end_time = route.end_time + shift
      bus = Occurrences.vehicle_attrs(@fleet, nil, vehicle_id, date, start_time)
      Row.new(
        trip_id: nil, school_route_id: route.id, date:, trip_run_id: nil, run_key: nil, slot_no: 1, part: 1,
        client_id: school.client_id, kind: "school_route", trip_label: route.title, start_time:, end_time:,
        starts_at: at(date, start_time), ends_at: at(date, end_time), shift_minutes: occ&.shift_minutes.to_i,
        pax: route.riders_count, price: 0, trip_value: 1, trip_assignment_id: nil, replacement_id: nil,
        original_vehicle_id: route_rep ? regular : nil, driver_name: nil, driver_phone: nil, **bus,
        **(route_rep ? original_driver(regular, date, start_time, bus) : {})
      )
    end
  end
end

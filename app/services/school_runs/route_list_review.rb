# Review step of Import Route List: the rows read from the file grouped into stops (same time and the same point text
# or postal code, or postal codes on one Saved Pick-up Point; `joins` overrides: Join Stop Above / Separate Stop),
# rows to check (no time, earlier than the row above, no parent phone, no postal code, on another School Run),
# the changes from the trip's current list, and trip params ready for POST /trips (or Apply).
# Postal codes are checked on OneMap by the front end.
module SchoolRuns
  class RouteListReview < ApplicationService
    WEEKDAYS = [ 1, 2, 3, 4, 5 ].freeze

    # read: a done DocumentRead of kind route_list; joins: [bool per row] (row i joins the stop above); trip: when importing onto one
    def initialize(read:, joins: nil, trip: nil)
      raise Error, "That read was not a route list" unless read.kind == "route_list"
      raise Error, "The list is still being read" unless read.done?

      @data = read.data
      @rows = @data[:rows]
      @joins = joins
      @trip = trip
      @read = read
    end

    def call
      groups = group_rows
      {
        meta: @data.except(:rows), joins: groups.flat_map { |g| g.each_with_index.map { |_, i| i.positive? } },
        stops: groups.map.with_index { |g, k| stop_for(g, k) }, flagged: @flagged,
        changes: @trip ? changes(groups) : nil, trip_attributes: trip_attributes(groups)
      }
    end

    private

    def group_rows
      flags = @joins || auto_joins
      others = students_elsewhere
      @flagged = 0
      groups = []
      @rows.each_with_index do |r, i|
        f = flags_for(r, i.positive? ? @rows[i - 1] : nil, others)
        @flagged += 1 if f.any?
        row = r.merge(index: i, flags: f)
        i.positive? && flags[i] ? groups.last << row : groups << [ row ]
      end
      groups
    end

    # Same time and the same point text, the same postal code, or postal codes on the same Saved Pick-up Point.
    def auto_joins
      norm = ->(s) { s.to_s.downcase.gsub(/[^a-z0-9]/, "") }
      @rows.each_with_index.map do |r, i|
        next false if i.zero?

        p = @rows[i - 1]
        next false if r[:time].nil? || r[:time] != p[:time]
        next true if norm.(r[:point]).present? && norm.(r[:point]) == norm.(p[:point])
        next true if r[:postal] && r[:postal] == p[:postal]

        a = point_for(r[:postal])
        a.present? && a == point_for(p[:postal])
      end
    end

    def flags_for(r, prev, others)
      f = []
      if r[:time].nil? then f << "No time"
      elsif prev && prev[:time] && r[:time] < prev[:time] then f << "Earlier than the row above"
      end
      f << "No parent phone" if r[:phone].nil? && r[:phone2].nil?
      f << "No postal code" if r[:postal].nil?
      f << "Also on #{others[r[:name].downcase]}" if others[r[:name].downcase]
      f
    end

    # Students on the company's other School Runs: {name (lower case) => trip title}.
    def students_elsewhere
      TripStopStudent.joins(trip_stop: :trip).merge(Trip.kept.school_run).where.not(trips: { id: @trip&.id })
                     .pluck("LOWER(trip_stop_students.name)", "trips.title").to_h
    end

    def point_for(postal) = (@points ||= {})[postal] ||= PickupPoint.for_postal(postal)

    def stop_for(rows, k)
      first = rows.first
      saved = rows.lazy.map { |r| point_for(r[:postal]) }.find(&:itself)
      name = saved&.name || first[:address] || first[:postal] || "Stop #{k + 1}"
      points = rows.filter_map { |r| r[:point] }.uniq
      {
        name:, time: first[:time], address: [ first[:address], first[:postal] ].compact.join(" ").presence,
        lat: saved&.lat, lng: saved&.lng, driver_note: saved&.note.presence || points.join(". ").presence,
        pickup_point_id: saved&.id, postal_codes: rows.filter_map { |r| r[:postal] }.uniq, rows:
      }
    end

    def am? = @data[:session] != "pm"

    def trip_attributes(groups)
      stops = groups.map.with_index { |g, k| stop_for(g, k) }
      used = Hash.new(0)
      stops.each { |s| used[s[:name]] += 1; s[:name] = "#{s[:name]} (#{used[s[:name]]})" if used[s[:name]] > 1 }
      school = { name: @data[:school] || "School", address: @data[:school_address], time: am? ? @data[:arrive_by] : @data[:leave_by], rows: [] }
      ordered = am? ? stops + [ school ] : [ school ] + stops
      {
        kind: "school_run", session: @data[:session], title: @trip&.title || [ @data[:school], @data[:label] ].compact.join(" ").presence,
        starts_on: @trip ? nil : @data[:start_date], days: @trip ? nil : WEEKDAYS, end_mode: @trip ? nil : "never",
        notes: @data[:notes],
        stops_attributes: ordered.each_with_index.map do |s, i|
          {
            position: i, name: s[:name], use: use_at(i, ordered.size), address: s[:address], lat: s[:lat], lng: s[:lng],
            driver_note: s[:driver_note], scheduled_time: s[:time],
            students_attributes: s[:rows].each_with_index.map do |r, j|
              { position: j, name: r[:name], class_name: r[:class_name], parent_name: r[:parent_name], phone: r[:phone], phone2: r[:phone2], note: r[:note] }.compact
            end
          }.compact
        end
      }.compact
    end

    # AM: every stop picks up and the school (last) drops off; PM: the school (first) picks up, every stop drops off.
    def use_at(i, n)
      return "pu" if i.zero?
      return "do" if i == n - 1

      am? ? "pu" : "do"
    end

    # Changes From the Current List: added, removed, and students whose time, stop or phone changed.
    def changes(groups)
      now = @trip.outbound_stops.flat_map { |s| s.students.map { |st| [ st.name.downcase, { name: st.name, time: s.scheduled_time_hm, stop: s.name, phone: st.phone } ] } }.to_h
      stops = groups.map.with_index { |g, k| stop_for(g, k) }
      fresh = stops.flat_map { |s| s[:rows].map { |r| [ r[:name].downcase, { name: r[:name], time: r[:time], stop: s[:name], phone: r[:phone] } ] } }.to_h
      changed = (fresh.keys & now.keys).filter_map do |k|
        diff = %i[time stop phone].select { |f| fresh[k][f] != now[k][f] }
        { name: fresh[k][:name], changed: diff, before: now[k].slice(*diff), after: fresh[k].slice(*diff) } if diff.any?
      end
      { added: (fresh.keys - now.keys).map { |k| fresh[k][:name] }, removed: (now.keys - fresh.keys).map { |k| now[k][:name] }, changed: }
    end
  end
end

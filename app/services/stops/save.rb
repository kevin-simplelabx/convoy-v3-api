# Save a Stop Library stop (new or changed) as the Stop editor does: a name, at least one PUDO point, a bus size on each,
# both a pick-up and a drop-off point when a school has a catchment on it; a new stop is named after the primary point's
# URA subzone. Moving, adding or removing points of a stop other schools use asks for confirmation first
# (code "confirm_required" with those schools). A stop made from a school (not the Library page) belongs to that school
# (library_status "school") and is linked to it.
module Stops
  class Save < ApplicationService
    PHYSICAL = %w[lat lng usage sizes].freeze

    def initialize(params, user:, stop: nil, school: nil, in_library: true, confirmed: false)
      @p = params
      @user = user
      @stop = stop
      @school = school
      @in_library = in_library
      @confirmed = confirmed
    end

    def call
      name = @p[:name].to_s.strip
      points = Array(@p[:points])
      raise Error, "Enter a stop name" if name.empty?
      raise Error, "Add at least one PUDO point" if points.empty?

      Stop.transaction do
        stop = @stop || Stop.new(created_by: @user)
        stop.name = name
        changed = sync_points(stop, points)
        check_coverage!(stop)
        new_stop!(stop) if stop.new_record?
        confirm!(stop) if changed && stop.persisted?
        stop.save!
        stop.all_points.each(&:save!)
        link_to_school(stop) if @stop.nil? && @school
        touch_schools(stop) if changed
        stop
      end
    end

    private

    # Updates, adds (next free letter) and retires points; true when the stop's points moved or changed use / sizes.
    def sync_points(stop, rows)
      current = stop.persisted? ? stop.all_points.to_a : []
      used = current.map(&:suffix)
      keep = []
      changed = false
      rows.each do |r|
        point = current.find { it.id.to_s == r[:id].to_s && it.retired_at.nil? }
        unless point
          letter = (StopPoint::LETTERS - used).first or raise Error, "A stop can have up to #{StopPoint::LETTERS.size} points"
          used << letter
          point = stop.all_points.build(suffix: letter)
          changed = true
        end
        point.assign_attributes(r.slice(:description, :usage, :lat, :lng, :street_view_url).merge(sizes: Array(r[:sizes]).map(&:to_s).uniq,
                                                                                             primary: !!r[:primary]))
        point.subzone_code = UraSubzone.at(point.lat, point.lng)&.code if point.lat_changed? || point.lng_changed? || point.new_record?
        changed ||= (point.changed & PHYSICAL).any?
        raise Error, "Point #{point.suffix} needs at least one bus size" if point.sizes.empty?
        raise Error, "Point #{point.suffix}: #{point.errors.full_messages.to_sentence}" unless point.valid?

        keep << point
      end
      (current - keep).each do |gone|
        next if gone.retired_at

        gone.retired_at = Time.current
        changed = true
      end
      keep.first.primary = true if keep.none?(&:primary)
      keep.select(&:primary).drop(1).each { it.primary = false }
      @live = keep
      changed
    end

    def check_coverage!(stop)
      catchment = stop.persisted? && stop.school_stops.any?(&:catchment?)
      return unless catchment

      uses = @live.map(&:usage)
      return if uses.intersect?(%w[pickup both]) && uses.intersect?(%w[dropoff both])

      raise Error, "Stops with postal codes or areas need both pick-up and drop-off points"
    end

    def new_stop!(stop)
      primary = @live.find(&:primary)
      zone = UraSubzone.at(primary.lat, primary.lng) or raise Error, "No URA subzone found for Point #{primary.suffix}. Move it inside Singapore"
      stop.subzone_code = zone.code
      stop.code = next_code(zone.code)
      stop.library_status = @in_library || @school.nil? ? "approved" : "school"
      stop.owner_school = @school
    end

    def next_code(prefix)
      taken = Stop.with_discarded.where("code LIKE ?", "#{prefix}-%").pluck(:code).to_set
      n = (1..).find { !taken.include?(format("%s-%04d", prefix, it)) }
      format("%s-%04d", prefix, n)
    end

    def confirm!(stop)
      others = stop.school_stops.includes(:school).reject { it.school_id == @school&.id }
      return if others.empty? || @confirmed

      raise Error.new("#{stop.code} is used by other schools. Confirm to change it for them too", code: "confirm_required",
                      details: { schools: others.map { |ss| { id: ss.school_id, name: ss.school.name, riders: SchoolStops.riders_covered(ss).size } } })
    end

    def link_to_school(stop) = SchoolStop.create!(school: @school, stop:)

    def touch_schools(stop)
      School.where(id: stop.school_stops.select(:school_id)).update_all(stops_changed_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end

# Record a booking or save changes from the booking form: the booking, its days and their trips with points, standby
# areas and vehicles (all sent each time; days and trips matched by id). Approved and rejected trips are locked: they
# keep their values and can't be removed. Each open trip's estimate is worked out again from the client's rate card.
module Bookings
  class Save < ApplicationService
    BOOKING_FIELDS = %i[client_id client_site_id client_end_customer_id service_for coordinator_name coordinator_org
                        coordinator_email coordinator_phone po_number cost_centre notes].freeze
    PERMIT = [ *BOOKING_FIELDS, { days: [ :id, :date, { trips: [ :id, *TripBuilder::PERMIT ] } ] } ].freeze

    def initialize(booking:, params:, user:, lock_version: nil)
      @booking = booking
      @params = params.to_h.deep_symbolize_keys
      @user = user
      @lock_version = lock_version
    end

    def call
      Booking.transaction do
        check_lock
        @booking.assign_attributes(@params.slice(*BOOKING_FIELDS))
        check_booking
        @old_days = @booking.days.includes(trips: [ :points, :standbys, { vehicles: :vehicle_type } ]).index_by(&:id)
        @old_trips = @old_days.values.flat_map(&:trips).index_by(&:id)
        @days = build_days
        remove_missing
        check_days
        estimate
        persist
        @booking
      end
    end

    private

    def check_lock
      return if @booking.new_record?
      raise ActiveRecord::StaleObjectError.new(@booking, "update") if !@lock_version.nil? && @lock_version.to_i != @booking.lock_version

      @booking.updated_at = Time.current
    end

    def check_booking
      raise Error, "Pick the client" if @booking.client.nil? || @booking.client.discarded?
      raise Error, "Enter the booking coordinator" if @booking.coordinator_name.blank?
      raise Error, "Pick a site of this client" if @booking.client_site && @booking.client_site.client_id != @booking.client_id
      raise Error, "Pick a customer of this client" if @booking.client_end_customer && @booking.client_end_customer.client_id != @booking.client_id

      @booking.service_for = @booking.client_end_customer.name if @booking.client_end_customer && @booking.service_for.blank?
    end

    def build_days
      list = Array(@params[:days])
      raise Error, "Add at least one day" if list.empty?
      raise Error, "No more than #{Booking::MAX_DAYS} days in a booking" if list.size > Booking::MAX_DAYS

      list.map do |d|
        day = d[:id].present? ? @old_days.fetch(d[:id].to_i) { raise ActiveRecord::RecordNotFound } : BookingDay.new
        day.date = parse_date(d[:date])
        trips = Array(d[:trips])
        raise Error, "#{label(day)}: add at least one trip" if trips.empty?
        raise Error, "No more than #{Booking::MAX_TRIPS_A_DAY} trips a day" if trips.size > Booking::MAX_TRIPS_A_DAY

        [ day, trips.each_with_index.map { |t, i| build_trip(day, t, i) } ]
      end
    end

    def build_trip(day, params, position)
      trip = params[:id].present? ? @old_trips.fetch(params[:id].to_i) { raise ActiveRecord::RecordNotFound } : BookingTrip.new
      if trip.locked?
        trip.day = day
        trip.position = position
        return trip
      end

      before = TripSummary.call(trip, trip.day.date) if trip.persisted?
      trip.day = day
      trip.position = position
      [ trip.points, trip.standbys, trip.vehicles ].each(&:delete_all) if trip.persisted?
      TripBuilder.call(trip, params)
      track_changes(trip, before, day) if before
      trip
    end

    # An edit to a trip the client asked for waits for the client to acknowledge it (Pending Client Acknowledgement).
    def track_changes(trip, before, day)
      items = TripSummary.changes(before, TripSummary.call(trip, day.date))
      return if items.empty?

      trip.mark_changed
      trip.assign_attributes(acknowledged_at: nil, acknowledged_by_name: nil, acknowledged_how: nil)
      trip.changes_made.build(items:, changed_by: @user)
    end

    def remove_missing
      kept_days = @days.map(&:first)
      kept_trips = @days.flat_map(&:last)
      (@old_trips.values - kept_trips).each do |t|
        raise Error, "An approved or rejected trip can't be removed" if t.locked?
      end
      @remove_trips = @old_trips.values - kept_trips
      @remove_days = @old_days.values - kept_days
    end

    def check_days
      dates = @days.map { |d, _| d.date }
      raise Error, "Pick the date of each day" if dates.any?(&:nil?)
      raise Error, "Two days have the same date" if dates.uniq.size != dates.size
      raise Error, "Days must be no more than #{Booking::MAX_SPAN_DAYS} days apart" if (dates.max - dates.min).to_i > Booking::MAX_SPAN_DAYS

      types = VehicleType.enabled_for(ActsAsTenant.current_tenant).index_by(&:id)
      @days.each { |day, trips| trips.reject(&:locked?).each { |t| check_trip(day, t, types) } }
    end

    def check_trip(day, trip, types)
      at = label(day)
      out = trip.points.select { |p| p.leg == "out" }
      back = trip.points.select { |p| p.leg == "back" }
      raise Error, "#{at}: pick the trip type" unless BookingTrip.kinds.key?(trip.kind)
      raise Error, "#{at}: enter the pick-up time" if trip.start_time.nil?
      raise Error, "#{at}: enter the pick-up point" if out.first.nil? || out.first.name.blank?
      raise Error, "#{at}: enter the drop-off point" if !trip.disposal? && (out.size < 2 || out.last.name.blank?)
      raise Error, "#{at}: name every stop, or remove it" if out[1...-1].to_a.any? { |p| p.name.blank? }
      raise Error, "#{at}: up to #{BookingTrip::MAX_STOPS} stops" if [ out.size - 2, back.size - 2 ].max > BookingTrip::MAX_STOPS
      raise Error, "#{at}: each point needs a pick-up, a drop-off or both" if trip.points.any? { |p| !BookingTripPoint::USES.include?(p.use) }
      if trip.two_way?
        raise Error, "#{at}: the return time must be after the pick-up time" unless trip.return_time.to_i > trip.start_time
        raise Error, "#{at}: enter the drop-off on the way back" if back.size == 1 || (back.size >= 2 && back.last.name.blank?)
      end
      raise Error, "#{at}: enter the standby area, or turn it off" if trip.standbys.any? { |s| s.leg == "out" && s.location.blank? }
      raise Error, "#{at}: enter the standby area for the return, or turn it off" if trip.standbys.any? { |s| s.leg == "back" && s.location.blank? }
      raise Error, "#{at}: enter the disposal hours" if trip.disposal? && !trip.hours.to_d.positive?
      raise Error, "#{at}: pick vehicle types the company offers" if trip.vehicles.any? { |v| !types.key?(v.vehicle_type_id.to_i) }
      raise Error, "#{at}: pick each vehicle type once" if trip.vehicles.map(&:vehicle_type_id).uniq.size != trip.vehicles.size

      count = trip.vehicles.sum(&:count)
      raise Error, "#{at}: request at least one vehicle" if count.zero?
      raise Error, "#{at}: no more than #{BookingTrip::MAX_VEHICLES} vehicles a trip" if count > BookingTrip::MAX_VEHICLES
    end

    def estimate
      pricer = Estimate.pricer_for(@booking.client)
      @days.each do |day, trips|
        trips.reject(&:locked?).each do |t|
          result = Estimate.call(client: @booking.client, trip: t, date: day.date, pricer:)
          t.estimate_amount = result.amount
          t.estimate_lines = result.lines
        end
      end
      @booking.estimate_amount = @days.flat_map(&:last).reject { |t| t.rejected? || t.cancelled? }.sum(&:estimate_amount)
    end

    # Days are saved after moved ones step aside (unique booking + date); trips after their days; removed days last,
    # once their kept trips have moved to another day.
    def persist
      if @booking.new_record?
        @booking.number = Booking.next_number(ActsAsTenant.current_tenant)
        @booking.created_by = @user
      end
      @booking.save!
      days = @days.map(&:first)
      days.select { |d| d.persisted? && d.date_changed? }.each_with_index do |d, i|
        date = d.date
        d.update_columns(date: Date.new(1900, 1, 1) + i)
        d.date = date
      end
      @days.each do |day, trips|
        day.booking = @booking
        trips.each { |t| t.booking = @booking }
        day.save!
        trips.each { |t| t.update!(day:) }
      end
      @remove_trips.each(&:destroy!)
      @remove_days.each { |d| d.reload.destroy! }
    end

    def parse_date(value)
      value.present? ? Date.iso8601(value.to_s) : nil
    rescue Date::Error
      nil
    end

    def label(day) = day.date ? day.date.strftime("%d/%m/%Y") : "A day"
  end
end

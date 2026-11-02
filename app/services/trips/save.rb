# Create or update a trip from the trip form. A new Ad Hoc / Charter trip with a return creates two trips linked to
# each other (outbound and "(Return)"): the return copies the outbound and takes its own start, stops, standby and buses.
module Trips
  class Save < ApplicationService
    Result = Data.define(:trip, :return_trip)

    # Copied from the outbound trip onto its return.
    RETURN_COPY = %w[client_id client_site_id kind label starts_on days end_mode ends_on occurrence_count skip_public_holidays
                     calendar_id pax luggage_on luggage_cabin luggage_medium luggage_large luggage_extra_large luggage_oversized
                     vehicles_count requestor_name requestor_email requestor_phone guest_is_requestor guest_name guest_phone notes
                     business_unit project booking_ref price price_per price_set price_basis trip_value trip_value_mode
                     trip_value_rounding operator_cost operator_cancel_rule subcontracted client_end_customer_id service_for
                     contractor_contact_name contractor_contact_phone require_contractor_app].freeze
    # Way back stops within this distance of a stop on the way there keep it one two-way trip for billing.
    TWO_WAY_METRES = 200

    def initialize(trip:, attributes:, user:, return_attributes: nil)
      @trip = trip
      @attributes = attributes
      @return_attributes = return_attributes.presence
      @user = user
    end

    def call
      Trip.transaction do
        @trip.assign_attributes(@attributes)
        @trip.created_by ||= @user
        creating = @trip.new_record?
        @trip.save!
        Timetable.call(@trip) if @trip.corporate_shuttle?
        return_trip = create_return! if creating && @return_attributes
        Occurrences::Sync.call(trips: [ @trip, return_trip ].compact)
        Result.new(@trip, return_trip)
      end
    end

    private

    def create_return!
      raise Error, "Only a new Ad Hoc / Charter trip can have a return" unless @trip.ad_hoc?

      ret = Trip.new(@trip.attributes.slice(*RETURN_COPY))
      ret.assign_attributes(@return_attributes.except(:return_billing))
      ret.title = "#{@trip.title} (Return)"
      ret.is_return = true
      ret.pair = @trip
      ret.created_by = @user
      ret.vehicle_requirements = @trip.vehicle_requirements.map { |r| TripVehicleRequirement.new(vehicle_type: r.vehicle_type, count: r.count) }
      copy_slots(ret) if ret.vehicle_slots.empty?
      check_return_time!(ret)
      save_return!(ret)
      @trip.update!(pair: ret, return_billing: billing_for(ret))
      ret
    end

    def copy_slots(ret)
      @trip.vehicle_slots.each { |s| ret.vehicle_slots.build(slot_no: s.slot_no, vehicle_id: s.vehicle_id, price: s.price) }
    end

    def check_return_time!(ret)
      return if ret.start_time.nil? || @trip.end_time.nil? || @trip.end_time >= 1440

      raise Error, "The return starts before the outbound trip ends" if ret.start_time < @trip.end_time
    end

    def save_return!(ret)
      ret.save!
    rescue ActiveRecord::RecordInvalid => e
      raise Error, "Return trip: #{e.record.errors.full_messages.to_sentence}"
    end

    # Two-way while every stop on the way back is within 200 m of a stop on the way there; else billed as 2 one-way trips.
    # When a stop has no pin yet, the form's own answer is used.
    def billing_for(ret)
      there = @trip.outbound_stops.filter_map { |s| s.lat && [ s.lat, s.lng ] }
      back = ret.outbound_stops
      return @return_attributes[:return_billing].presence || "one_way" if back.any? { |s| s.lat.nil? } || there.empty?

      near = back.all? { |s| there.any? { |p| Geo.metres(p, [ s.lat, s.lng ]) <= TWO_WAY_METRES } }
      near ? "two_way" : "one_way"
    end
  end
end

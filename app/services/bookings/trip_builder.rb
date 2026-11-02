# Puts the booking form's values for one trip onto a BookingTrip in memory: fields, points of each way, standby
# areas and vehicles. The trip's old children must be gone (Save deletes them first).
module Bookings
  class TripBuilder
    FIELDS = %i[kind label start_time return_time hours airport_direction flight_number terminal wait_minutes meet_and_greet
                signboard_name pax luggage_on luggage_cabin luggage_medium luggage_large luggage_extra_large luggage_oversized
                contact_name contact_phone note distance_km return_distance_km].freeze
    POINT_FIELDS = %i[name address lat lng use note].freeze
    STANDBY_FIELDS = %i[location minutes lat lng note].freeze
    PERMIT = [ *FIELDS, { points: POINT_FIELDS }, { back_points: POINT_FIELDS }, { standby: STANDBY_FIELDS },
               { return_standby: STANDBY_FIELDS }, { vehicles: %i[vehicle_type_id count] } ].freeze

    def self.call(trip, params) = new(trip, params.to_h.deep_symbolize_keys).call

    def initialize(trip, params)
      @trip = trip
      @params = params
    end

    def call
      @trip.assign_attributes(@params.slice(*FIELDS))
      @trip.airport_direction = @trip.airport? ? (@trip.airport_direction || "arrival") : nil
      @trip.return_time = nil unless @trip.two_way?
      @trip.hours = nil unless @trip.disposal?
      points("out", @params[:points])
      points("back", @params[:back_points]) if @trip.two_way?
      standby("out", @params[:standby])
      standby("back", @params[:return_standby]) if @trip.two_way?
      Array(@params[:vehicles]).each do |v|
        @trip.vehicles.build(vehicle_type_id: v[:vehicle_type_id], count: v[:count].to_i) if v[:count].to_i.positive?
      end
      @trip
    end

    private

    def points(leg, list)
      Array(list).each_with_index do |p, i|
        @trip.points.build(p.slice(*POINT_FIELDS).merge(leg:, position: i, name: p[:name].to_s.strip, use: p[:use].presence || "both"))
      end
    end

    def standby(leg, value)
      return if value.blank?

      @trip.standbys.build(value.slice(*STANDBY_FIELDS).merge(leg:, location: value[:location].to_s.strip, minutes: value[:minutes].presence || 10))
    end
  end
end

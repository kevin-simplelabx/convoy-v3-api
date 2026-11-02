# Estimate of a booking trip from the client's rate card (else the default card), for every vehicle asked for:
# One Way and Airport = trip rate at the pick-up time; Two Way = trip rate out (pick-up time) + back (return time);
# Disposal = hourly rate x hours (+ km after the free km on an Hourly + Distance card).
# Distance and extra stops: each one-way leg; a Two Way whose way back strays more than 200 m from the way there is
# priced as two one-way trips (each way its own km and stops). Meet and Greet once per airport arrival.
# km come from the front end's road route (distance_km, return_distance_km); without them no distance is charged.
module Bookings
  class Estimate < ApplicationService
    TWO_WAY_METRES = 200
    Result = Data.define(:amount, :lines, :without_rate, :card)

    def initialize(client:, trip:, date:, pricer: nil)
      @client = client
      @trip = trip
      @date = date
      @pricer = pricer
    end

    def call
      pricer = @pricer || pricer_for(@client)
      return Result.new(0.to_d, [], @trip.vehicles_count, nil) if pricer.nil?

      @p = pricer
      lines = []
      without = 0
      @trip.vehicles.each do |v|
        next if v.count.to_i <= 0

        legs = vehicle_legs(v.vehicle_type)
        each = legs.sum(&:amount)
        without += v.count if each.zero? || legs.any?(&:missing)
        lines << { kind: "vehicles", text: "#{v.count} x #{v.vehicle_type.name}", vehicle_type_id: v.vehicle_type_id, count: v.count,
                   amount: (each * v.count).round(2).to_s, lines: legs.map { |l| { text: l.text, amount: l.amount.round(2).to_s } } }
      end
      if @trip.arrival_with_meet_and_greet? && (fee = @p.meet_and_greet_fee).positive?
        lines << { kind: "meet_and_greet", text: "Meet and Greet", amount: fee.round(2).to_s, lines: [ { text: "Once per trip", amount: fee.round(2).to_s } ] }
      end
      Result.new(lines.sum { |l| l[:amount].to_d }.round(2), lines, without, @p.card)
    end

    def self.pricer_for(client)
      card = client&.rate_card && !client.rate_card.archived? ? client.rate_card : RateCard.active.find_by(default_card: true) || RateCard.active.first
      card && RateCards::Pricer.new(RateCard.includes(RateCards::Quote::INCLUDES).find(card.id))
    end

    private

    def pricer_for(client) = self.class.pricer_for(client)

    def vehicle_legs(type)
      legs = base_legs(type)
      if @trip.disposal?
        km = @p.disposal_km(@trip.distance_km, type)
        free = @p.card.disposal_free_km.to_f
        text = "Distance #{km_text(@trip.distance_km)} planned#{free.positive? ? ", first #{free.round(1)} km free" : ''}, GPS km if higher"
        legs << leg(text, km) if km.positive?
      elsif separate_return?
        [ [ @trip.distance_km, @trip.stops_count, "way there" ], [ @trip.return_distance_km, @trip.stops_count(@trip.back_points), "way back" ] ].each do |km, stops, way|
          distance = @p.distance_add(km, type)
          fee = @p.stop_fee(stops, type)
          legs << leg("Distance #{km_text(km)}, #{way}", distance) if distance.positive?
          legs << leg("#{stops} extra #{'stop'.pluralize(stops)}, #{way}", fee) if fee.positive?
        end
      else
        ways = @trip.two_way? ? 2 : 1
        both = ways > 1 ? ", both ways" : ""
        distance = @p.distance_add(@trip.distance_km, type) * ways
        fee = @p.stop_fee(@trip.stops_count, type) * ways
        legs << leg("Distance #{km_text(@trip.distance_km)}#{both}", distance) if distance.positive?
        legs << leg("#{@trip.stops_count} extra #{'stop'.pluralize(@trip.stops_count)}#{both}", fee) if fee.positive?
      end
      legs
    end

    def base_legs(type)
      if @trip.two_way?
        back = separate_return? ? "Return, priced as a one-way trip" : "Return"
        [ @p.leg("Out", @date, @trip.start_time, type), @p.leg(back, @date, @trip.return_time.to_i, type) ]
      elsif @trip.disposal?
        [ @p.leg("Disposal", @date, @trip.start_time, type, hours: @trip.hours.to_d) ]
      else
        [ @p.leg(@trip.airport? ? "Airport Transfer" : "One Way", @date, @trip.start_time, type) ]
      end
    end

    # Two-way rule: every point of the way back (but its first) within 200 m of a point of the way there.
    # Points without a pin yet keep it two-way.
    def separate_return?
      return @separate if defined?(@separate)

      there = @trip.out_points.filter_map(&:pin)
      back = @trip.back_points.drop(1)
      @separate = @trip.two_way? && there.size == @trip.out_points.size && back.all?(&:pin) &&
                  back.any? { |b| there.none? { |t| Geo.metres(t, b.pin) <= TWO_WAY_METRES } }
    end

    def leg(text, amount) = RateCards::Pricer::Leg.new(text, amount.to_d.round(2), false)
    def km_text(km) = "#{km.to_f.round(1)} km"
  end
end

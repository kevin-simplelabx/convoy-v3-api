# Price of one run as a one-way trip from the client's rate card (Corporate Shuttle Price From Rate Card):
# the period's trip rate for the vehicle type at the pick-up date and time, plus the distance band on the route
# distance and the fee for each stop between the first pick-up and the last drop-off.
# km comes from the front end's road route (OSRM); without it no distance charge is added.
module RateCards
  class Quote < ApplicationService
    Line = Data.define(:text, :amount)
    Result = Data.define(:card, :amount, :lines, :missing)
    INCLUDES = { periods: %i[ranges rates], distance_bands: [], amounts: [] }.freeze

    def initialize(client:, date:, start_time:, vehicle_type:, km: nil, extra_stops: 0)
      @client = client
      @date = date
      @minute = Clock.minutes(start_time)
      @type = vehicle_type
      @km = km&.to_f
      @stops = extra_stops.to_i
    end

    def call
      card = RateCard.includes(INCLUDES).for_client(@client)
      return Result.new(nil, 0, [], "No rate card") if card.nil?

      pricer = Pricer.new(card)
      base = pricer.leg("One Way", @date, @minute, @type)
      lines = [ Line.new(base.text, base.amount) ]
      distance = pricer.distance_add(@km, @type)
      lines << Line.new("Distance #{@km.round(1)} km", distance) if distance.positive?
      fee = pricer.stop_fee(@stops, @type)
      lines << Line.new("#{@stops} extra #{'stop'.pluralize(@stops)}", fee) if fee.positive?
      Result.new(card, lines.sum(&:amount).round(2), lines, base.missing ? base.text : nil)
    end
  end
end

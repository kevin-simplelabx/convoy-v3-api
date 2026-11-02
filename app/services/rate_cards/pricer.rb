# Prices from one rate card (loaded with periods, ranges, rates, bands and amounts): the period covering a date and
# time (an override wins), the trip or hourly rate of a vehicle type in it, and the distance, stop and disposal extras.
# Used by Quote (Price From Rate Card) and Bookings::Estimate.
module RateCards
  class Pricer
    Leg = Data.define(:text, :amount, :missing)

    attr_reader :card

    def initialize(card)
      @card = card
      @holidays = {}
    end

    def period_for(date, minute)
      holiday = @holidays.fetch(date) { @holidays[date] = PublicHoliday.exists?(date:) }
      card.periods.select(&:override).find { |p| p.covers?(date, minute, holiday:) } ||
        card.periods.reject(&:override).find { |p| p.covers?(date, minute, holiday:) }
    end

    # One priced leg: "Out, Peak" or "Disposal, Off Peak 4 h x S$45.00", or a missing rate (amount 0).
    def leg(label, date, minute, vehicle_type, hours: nil)
      period = period_for(date, minute)
      return Leg.new("#{label}: no period covers #{Clock.hm(minute)}", 0.to_d, true) if period.nil?

      rate = period.rates.find { |r| r.vehicle_type_id == vehicle_type.id }
      return Leg.new("#{label}: #{vehicle_type.name} not on #{card.name}", 0.to_d, true) if rate.nil?

      if hours
        Leg.new("#{label}, #{period.name} #{hours.to_d.to_s('F')} h x #{money(rate.hourly_rate)}", (rate.hourly_rate * hours.to_d).round(2), false)
      else
        Leg.new("#{label}, #{period.name}", rate.trip_rate.to_d, false)
      end
    end

    # The distance band amount for the route km (each one-way leg); the last band may charge per km beyond the one before.
    def distance_add(km, vehicle_type)
      return 0.to_d unless card.distance_pricing? && km.to_f.positive?

      lower = 0.0
      card.distance_bands.each_with_index do |band, i|
        last = i == card.distance_bands.size - 1 || band.up_to_km.nil?
        amount = card.amount_for("distance_band", vehicle_type, band:)
        return (band.per_km ? [ km.to_f - lower, 0 ].max * amount : amount).to_d.round(2) if last
        return amount if km.to_f <= band.up_to_km.to_f

        lower = band.up_to_km.to_f
      end
      0.to_d
    end

    def stop_fee(stops, vehicle_type)
      return 0.to_d unless card.stop_fees? && stops.to_i.positive?

      (stops.to_i * card.amount_for("stop_fee", vehicle_type)).round(2)
    end

    # Hourly + Distance disposal: per km after the free km.
    def disposal_km(km, vehicle_type)
      return 0.to_d unless card.disposal_hourly_distance? && km.to_f.positive?

      ([ km.to_f - card.disposal_free_km.to_f, 0 ].max * card.amount_for("disposal_km", vehicle_type)).to_d.round(2)
    end

    def meet_and_greet_fee = card.meet_and_greet? ? card.meet_and_greet_fee.to_d : 0.to_d

    def money(amount) = format("S$%.2f", amount)
  end
end

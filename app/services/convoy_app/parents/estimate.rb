# Convoy App › Request School Bus › Review and Estimated Fare: the fare a child would pay, from the school's real Bus Fares
# (the same quote Convoy OS starts from on Accept, `BusRequests::Fare.base` over `FareTables::Calc`): the tier for the
# straight-line distance from school to the pick-up point (the drop-off point for afternoon only), for the billing period
# the start falls in, two ways or one way; plus the CCA bus when the table charges it per billing period (an annual fee
# split over the periods). Per-ride CCA is booked week by week instead. shown = false when the year's registration hides
# fares from parents (pass registration:). Call inside the school's company.
module ConvoyApp
  module Parents
    class Estimate < ApplicationService
      def initialize(school:, year:, point:, am:, pm:, cca:, start_on:, registration: nil)
        @school = school
        @year = year
        @point = point
        @am = am
        @pm = pm
        @cca = cca
        @start_on = start_on
        @registration = registration
      end

      # { shown:, amount: (fare + CCA, nil when no Bus Fares apply), fare:, cca:, cca_per_ride:, unit:, km:, text: }
      def call
        req = BusRequest.new(school: @school, academic_year: @year, kind: "new", am: @am, pm: @pm, start_on: @start_on, lat: @point&.dig(:lat),
                             lng: @point&.dig(:lng), postal: @point&.dig(:postal))
        base = ::BusRequests::Fare.base(req)
        table = ::BusRequests::Fare.table_for(@school, @year)
        cca = @cca ? cca_amount(table, base[:tier], @start_on) : nil
        fare = base[:amount]
        { shown: @registration.nil? || @registration.show_fare, amount: fare && (fare + cca.to_d).round(2), fare:, cca:,
          cca_per_ride: (@cca ? self.class.per_ride(table) : nil), unit: base[:unit], km: base[:km]&.to_d&.round(1), text: text(base, fare) }
      end

      # CCA charged per ride (booked week by week in CCA Bus), as CcaRides.fares_price.
      def self.per_ride(table)
        table&.cca_on && table.cca_per == "trip" && table.cca_price == "fixed" && table.cca_fixed.to_d.positive? ? table.cca_fixed.to_d : nil
      end

      private

      def text(base, fare)
        return "The fare comes with the transport company's quote" unless fare

        way = @am && @pm ? "two ways" : "one way"
        "About #{base[:km]&.round(1)} km from school · #{way} S$#{format('%.2f', fare)} a #{base[:unit]}"
      end

      # The CCA bus a billing period: the table's fixed annual CCA fee (or the tier's), split equally over the periods
      # or by their CCA days, for the period the start falls in.
      def cca_amount(table, tier, start_on)
        return unless table&.cca_on && table.cca_per == "period" && tier

        annual = table.cca_price == "tier" ? table.tiers[tier - 1]&.cca_fare : table.cca_fixed
        return unless annual.to_d.positive?

        periods = FareTables.periods(table.academic_year, table)
        return if periods.empty?

        weights = table.cca_split == "days" && periods.sum { it[:cca_days].to_i }.positive? ? periods.map { it[:cca_days].to_i } : periods.map { 1 }
        k = periods.index { start_on && it[:starts_on] && it[:starts_on] <= start_on && start_on <= it[:ends_on] } || 0
        (annual.to_d * weights[k] / weights.sum).round(2)
      end
    end
  end
end

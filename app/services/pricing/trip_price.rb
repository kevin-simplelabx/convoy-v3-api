# Client price of one run (port of logic/pricing.js runPrice): what a vehicle slot of a trip earns on a date.
# - Shuttles: the price table. A day or month figure is spread over the runs it covers (and the month's run days);
#   a whole-route figure is shared over the vehicles.
# - Other trips: the slot's price (whole route shared over vehicles, or its own when set each); Disposal at an hourly
#   rate times the hours; slot 1 carries the Meet and Greet fee; charged per day or month for recurring trips.
module Pricing
  class TripPrice
    def initialize(trip, context)
      @trip = trip
      @ctx = context
    end

    # Amount for vehicle slot on a date, for a shuttle run (TripRun) or a plain trip.
    def run_price(slot:, date:, run: nil)
      return shuttle_price(run, slot, date) if @trip.corporate_shuttle? && run

      case @trip.price_basis
      when "trip" then amount(slot)
      when "day" then slot_price(slot)
      else cents(slot_price(slot) * month_factor(date) / month_days(date))
      end
    end

    # Price of vehicle slot n: a whole-route price is shared over the vehicles, else the slot's own price or the trip's.
    def slot_price(slot)
      n = @trip.vehicles_count
      return cents(@trip.price / n) if n > 1 && @trip.price_per_route?

      own = @trip.price_each? ? @trip.vehicle_slots.find { |s| s.slot_no == slot }&.price : nil
      (own || @trip.price).to_d
    end

    # The slot's amount: Disposal hourly rate x hours; slot 1 adds the Meet and Greet fee.
    def amount(slot)
      p = slot_price(slot)
      a = @trip.disposal? && @trip.hourly_rate? ? cents(p * hours) : p
      slot == 1 ? cents(a + meet_fee) : a
    end

    def meet_fee
      return 0.to_d unless @trip.airport_transfer? && @trip.meet_and_greet? && !@trip.departure?

      [ @trip.meet_and_greet_fee.to_d, 0 ].max
    end

    def hours = cents((@trip.end_time - @trip.start_time) / 60.0)

    # School Run month factor: 1 for a paid month, 0 or the share for unpaid ones; when No School days are not charged,
    # reduced by the share of runs lost to the calendar's No School days.
    def month_factor(date)
      return 1 unless @trip.school_run?

      f = @trip.paid_share(date.month)
      return f if f.zero? || @trip.charge_no_school_days? || @trip.calendar_id.nil?

      runs = @ctx.trip_dates(@trip, date.beginning_of_month, date.end_of_month).size
      lost = @ctx.no_school_days(@trip, date.beginning_of_month, date.end_of_month)
      runs + lost > 0 ? f * runs / (runs + lost).to_f : f
    end

    private

    def shuttle_price(run, slot, date)
      per_route = @trip.vehicles_count == 1 || @trip.price_per_route?
      by = @trip.price_by_direction? && !@trip.shuttle_return? ? "all" : @trip.price_by
      cell = find_cell(by, run, per_route ? nil : slot) or return 0.to_d

      a = cell.amount.to_d / (per_route ? @trip.vehicles_count : 1)
      unless @trip.charge_per_trip?
        a /= [ runs_in_row(by, run), 1 ].max
        a /= month_days(date) if @trip.charge_per_month?
      end
      cents(a)
    end

    def find_cell(by, run, slot)
      @trip.price_cells.find do |c|
        c.slot_no == slot &&
          case by
          when "all" then c.direction.nil? && c.trip_run_id.nil?
          when "direction" then c.direction == run.direction && c.trip_run_id.nil?
          else c.trip_run_id == run.id
          end
      end
    end

    def runs_in_row(by, run)
      case by
      when "all" then @trip.runs.size
      when "direction" then @trip.runs.count { |r| r.direction == run.direction }
      else 1
      end
    end

    # Days the trip runs in the month of the date (at least 1), to spread a monthly amount.
    def month_days(date)
      [ @ctx.trip_dates(@trip, date.beginning_of_month, date.end_of_month).size, 1 ].max
    end

    def cents(v) = v.to_d.round(2)
  end
end

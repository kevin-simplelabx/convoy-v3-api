# What a driver earns in a month from bonuses (Earnings and the Salary Simulator). Trip Target bonuses are worked out
# from the month's trips: daily (each day), weekly (Monday–Sunday weeks inside the month), monthly. On-time and
# attendance bonuses only in the simulator (from the percentages typed in). Quarterly and longer periods are not
# worked out for one month. A bonus overlapping the scheme's own incentive of the same period adds to it, replaces it
# (supercede) or gives way (prevail). Paid at the end of the period / next payroll counts this month; later payments are listed.
module Pay
  class Bonuses < ApplicationService
    # result: Pay::Month::Result. driver: nil in the simulator (eligibility and sign-up are assumed).
    def initialize(result:, driver: nil, on_time: nil, attendance: nil)
      @result = result
      @driver = driver
      @on_time = on_time
      @attendance = attendance
      @month = result.month
      @trips_by_day = result.parts.flat_map { |p| p.days.map { |d, x| [ d, x[:trips].to_d ] } }.to_h
    end

    def call
      scheme_ids = @result.parts.filter_map { |p| p.scheme&.id }
      return [] if scheme_ids.empty?

      PayBonus.kept.includes(:tiers, :payments, :bonus_schemes, :bonus_drivers).select do |b|
        b.covers?(@month, @month.end_of_month) && (b.all_schemes? || b.bonus_schemes.any? { |s| scheme_ids.include?(s.pay_scheme_id) }) && joined?(b)
      end.filter_map { |b| work_out(b) }
    end

    private

    def joined?(b)
      return true unless @driver

      (b.eligible_driver_ids.empty? || b.eligible_driver_ids.include?(@driver.id)) &&
        (!b.requires_sign_up? || b.signed_up_driver_ids.include?(@driver.id))
    end

    def work_out(b)
      days = (@month..@month.end_of_month).select { |d| d >= b.starts_on && (b.ends_on.nil? || d <= b.ends_on) }
      amount, points, sub =
        if !b.trip_target? then reliability(b)
        elsif b.every_daily? then periods(b, days.map { |d| [ d ] }, "days")
        elsif b.every_weekly? then periods(b, days.select(&:sunday?).filter_map { |sun| (sun - 6..sun).to_a if (sun - 6) >= @month }, "weeks")
        elsif b.every_monthly? then periods(b, [ days ], "month")
        else return { bonus_id: b.id, name: b.name, sub: "#{b.frequency.humanize} periods are not worked out for one month", amount: 0, points: 0, paid_now: false }
        end
      return nil if amount.nil?

      amount, adjust = overlap(b, amount)
      paid_now = b.paid_end_of_period? || b.paid_next_payroll_cycle?
      { bonus_id: b.id, name: b.name, sub:, amount: amount.round(2), adjust: adjust.round(2), points:, paid_now:,
        note: paid_now ? nil : later_note(b) }
    end

    # Each period (list of dates) pays its tier for the trips in it.
    def periods(b, list, unit)
      hits = list.filter_map do |dates|
        trips = dates.sum { |d| @trips_by_day[d] || 0 }
        tier = b.tier_for(trips)
        tier && [ tier.pay_for(trips), tier.points.to_i ]
      end
      sub = unit == "month" ? (hits.any? ? "Target reached" : "Target not reached") : "#{hits.size} of #{list.size} #{unit} reached a tier"
      [ hits.sum(0.to_d) { |a, _| a }, hits.sum { |_, p| p }, sub ]
    end

    def reliability(b)
      value = b.reliability_otp? ? @on_time : @attendance
      return nil if value.nil? || !b.every_monthly?

      tier = b.tier_for(value.to_d)
      [ tier ? tier.amount : 0.to_d, tier&.points.to_i, "#{value}% #{b.reliability_otp? ? 'on time' : 'attendance'}" ]
    end

    # [amount, adjustment to the scheme's incentive] by the overlap rule of the period.
    def overlap(b, amount)
      key = { "daily" => :daily_volume, "weekly" => :weekly_target, "monthly" => :monthly_target }[b.frequency]
      scheme = key ? @result.parts.sum(0.to_d) { |p| p.parts[key].to_d } : 0
      return [ amount, 0.to_d ] unless key && amount.positive? && scheme.positive?

      case b.public_send(:"overlap_#{b.frequency}")
      when "prevail" then [ 0.to_d, 0.to_d ]
      when "supercede" then [ amount, -scheme ]
      else [ amount, 0.to_d ]
      end
    end

    def later_note(b)
      b.paid_x_months_later? ? "Paid #{b.payout_delay_months} #{'month'.pluralize(b.payout_delay_months)} after the period" : "Paid later in #{b.payments.size} parts"
    end
  end
end

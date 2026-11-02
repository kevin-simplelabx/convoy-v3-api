# A driver's points: balance (what is left of lots not expired), earned, used, expired, expiring in the next 60 days,
# and the history; Award (a new lot, 24 months) and Deduct (from the lots expiring first, up to the balance).
module Pay
  class Points
    def initialize(driver, today: Date.current)
      @driver = driver
      @today = today
    end

    def lots = @lots ||= DriverPointLot.where(driver: @driver).includes(:awarded_by).order(:expires_on, :id).to_a
    def deductions = @deductions ||= DriverPointDeduction.where(driver: @driver).includes(:deducted_by).to_a

    def balance = lots.reject { |l| l.expired?(@today) }.sum(&:remaining)

    def summary
      { balance:, earned: lots.sum(&:points), used: deductions.sum(&:points), expired: lots.select { |l| l.expired?(@today) }.sum(&:remaining),
        expiring_soon: lots.select { |l| !l.expired?(@today) && l.expires_on <= @today + 60 }.sum(&:remaining) }
    end

    # Newest first: awards (status active / used / expired) and deductions.
    def history
      awards = lots.map do |l|
        { kind: "award", id: l.id, points: l.points, remaining: l.remaining, reason: l.reason, source: l.source, on: l.awarded_on,
          expires_on: l.expires_on, by: l.awarded_by&.shown_name, status: lot_status(l), at: l.created_at }
      end
      used = deductions.map { |d| { kind: "deduct", id: d.id, points: -d.points, reason: d.reason, on: d.deducted_on, by: d.deducted_by&.shown_name, status: "used", at: d.created_at } }
      (awards + used).sort_by { |h| [ h[:on], h[:at] ] }.reverse.map { |h| h.except(:at) }
    end

    def lot_status(lot)
      return "expired" if lot.expired?(@today) && lot.remaining.positive?

      lot.remaining.zero? ? "used" : "active"
    end

    def award!(points:, reason:, user:, source: "manual", bonus: nil, month: nil)
      DriverPointLot.create!(company_id: @driver.company_id, driver: @driver, points:, remaining: points, source:, reason:,
                             awarded_on: @today, expires_on: @today + DriverPointLot::LIFETIME, awarded_by: user, pay_bonus: bonus,
                             driver_pay_month: month, audit_comment: "Awarded #{points} points: #{reason}")
    end

    def deduct!(points:, reason:, user:)
      DriverPointLot.transaction do
        live = DriverPointLot.where(driver: @driver).live(@today).where("remaining > 0").order(:expires_on, :id).lock.to_a
        have = live.sum(&:remaining)
        raise ApplicationService::Error, "#{@driver.name} has only #{have} points" if points > have

        deduction = DriverPointDeduction.create!(company_id: @driver.company_id, driver: @driver, points:, reason:, deducted_on: @today,
                                                 deducted_by: user, audit_comment: "Deducted #{points} points: #{reason}")
        left = points
        live.each do |lot|
          break if left.zero?

          take = [ lot.remaining, left ].min
          deduction.allocations.create!(driver_point_lot: lot, points: take)
          lot.update_columns(remaining: lot.remaining - take) # rubocop:disable Rails/SkipsModelValidations
          left -= take
        end
        deduction
      end
    end
  end
end

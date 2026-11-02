# HR > Earnings > Confirm Month: once the month has ended, the driver has a pay scheme and no paid run has an issue
# raised, the pay is frozen (total, breakdown rows, each paid run's amount). Reopen Month (Admin) deletes it.
module Pay
  class ConfirmMonth < ApplicationService
    def initialize(driver:, month:, user:)
      @driver = driver
      @month = month.beginning_of_month
      @user = user
    end

    def call
      out = DriverMonth.call(driver: @driver, month: @month)
      reason = self.class.blocker(out)
      raise Error, reason if reason

      total = out.total.round(2)
      runs = out.runs.count { |r| r.status == "completed" }
      DriverPayMonth.transaction do
        record = DriverPayMonth.create!(company_id: @driver.company_id, driver: @driver, month: @month, total:, trips: out.result.trips,
                                        runs_count: runs, confirmed_by: @user, confirmed_at: Time.current,
                                        audit_comment: "Confirmed #{@month.strftime('%b %Y')} at S$#{format('%.2f', total)} from #{runs} trips")
        save_lines(record, out.result)
        save_bonus_lines(record, out)
        save_runs(record, out)
        award_bonus_points(record, out)
        record
      end
    end

    # Why the month can't be confirmed yet, or nil.
    def self.blocker(out)
      return "#{out.month.strftime('%B %Y')} is already confirmed" if out.confirmed
      return "The month can be confirmed from #{out.month.next_month.strftime('%-d %b %Y')}" if out.month.next_month > Date.current
      return "No pay scheme assigned. Pick one in Drivers" if out.result.parts.none?(&:scheme)

      held = out.runs.count { |r| r.status == "issue" }
      "#{held} #{held == 1 ? 'trip has' : 'trips have'} an issue raised. Clear them first" if held.positive?
    end

    private

    def save_lines(record, result)
      i = 0
      result.parts.each do |p|
        p.rows.each do |row|
          record.lines.create!(position: i += 1, part_from: p.from, part_to: p.to, scheme_name: p.scheme&.name,
                               label: row[:label], amount: row[:amount], text: row[:text])
        end
      end
    end

    def save_bonus_lines(record, out)
      out.bonuses.select { |b| b[:paid_now] }.each_with_index do |b, i|
        record.lines.create!(position: 1000 + i, label: "Bonus: #{b[:name]}", amount: b[:amount] + b[:adjust].to_d, text: b[:sub])
      end
    end

    # Points of the bonuses paid this month go to the driver's points (a lot each).
    def award_bonus_points(record, out)
      points = Points.new(@driver)
      out.bonuses.select { |b| b[:paid_now] && b[:points].to_i.positive? }.each do |b|
        points.award!(points: b[:points].to_i, reason: "Bonus: #{b[:name]}, #{@month.strftime('%b %Y')}", user: @user, source: "bonus",
                      bonus: PayBonus.find(b[:bonus_id]), month: record)
      end
    end

    def save_runs(record, out)
      out.runs.select { |r| r.status == "completed" }.each do |r|
        o = r.occurrence
        record.runs.create!(occurrence_id: o.id, occurrence_date: o.date, trip_label: o.trip_label, trip_value: r.hours ? nil : o.trip_value,
                            hours: r.hours, amount: out.result.job_pay[o.id] || 0)
      end
    end
  end
end

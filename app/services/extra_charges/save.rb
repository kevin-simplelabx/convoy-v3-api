# Add or edit an Extra Charge (only while Scheduled): needs the year's fares locked; checks as the Extra Charge form does
# (HTML saveIt, school-finance.js); targets are tiers / zones of the year's table (`tier_ids`) or bus sizes when the
# school pays per bus (`bus_types`), none = every rider. Returns the charge and a warning when no bill of the year falls
# between its months (a one-off needs a bill in its month).
module ExtraCharges
  class Save < ApplicationService
    def initialize(year, params, user:, charge: nil)
      @year = year
      @params = params
      @user = user
      @charge = charge
    end

    def call
      table = @year.fare_table
      raise Error, "Save and lock the Bus Fares first" unless table && SchoolSetup.locked?(school: @year.school, year: @year, section: :fares)
      raise Error, "Only a charge that has not started can change" if @charge && @charge.state != "scheduled"

      charge = @charge || @year.school.fare_adjustments.new(academic_year: @year, created_by: @user)
      charge.assign_attributes(name: @params[:name].to_s.strip, kind: @params[:kind], value: value, note: @params[:note],
                               from_month: month(@params[:from_month]), to_month: month(@params[:to_month]))
      bills = FareTables.bill_months(@year, table)
      check!(charge, bills)
      targets = Targets.call(table, @params)
      FareAdjustment.transaction do
        charge.save!
        charge.targets.delete_all
        targets.each { charge.targets.create!(it) }
      end
      [ charge.reload, warning(charge, bills) ]
    end

    private

    def value
      v = @params[:value]
      v.present? && v.to_s.match?(/\A-?\d+(\.\d+)?\z/) ? v.to_d.round(2) : nil
    end

    def check!(c, bills)
      now = Date.current.beginning_of_month
      raise Error, "Give the charge a name" if c.name.blank?
      raise Error, "Enter an amount above 0" unless c.value&.positive?
      raise Error, "Percentage must be 100 or less" if c.kind == "pct" && c.value > 100
      raise Error, "Pick the start month" unless c.from_month
      raise Error, "Bills before this month are already raised. Pick this month or later" if c.from_month < now
      raise Error, "No bill is raised in that month" if c.kind == "once" && bills.exclude?(c.from_month)
      raise Error, "End month must be on or after the start month" if c.kind != "once" && c.to_month && c.to_month < c.from_month
    end

    # HTML noBillTxt for a charge over months: no bill of this year falls in them.
    def warning(c, bills)
      return if c.kind == "once" || bills.any? { |m| m && m >= c.from_month && (c.to_month.nil? || m <= c.to_month) }

      from = c.from_month.strftime("%B %Y")
      return "No AY #{@year.key} bills fall between #{from} and #{c.to_month.strftime('%B %Y')}" if c.to_month

      "No AY #{@year.key} bills fall from #{from} to the end of the year. It starts on AY bills of later years"
    end

    def month(v)
      return nil if v.blank?

      Date.strptime(v.to_s[0, 7], "%Y-%m")
    rescue Date::Error
      raise Error, "Months must look like 2026-11"
    end
  end
end

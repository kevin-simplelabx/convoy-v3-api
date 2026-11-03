# Add or edit an Extra Charge (only while Scheduled): needs the year's fares locked; starts this month or later.
# Returns the charge and a warning when no bill falls between its months.
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
      charge.assign_attributes(@params.slice(:name, :kind, :value, :note).merge(from_month: month(@params[:from_month]), to_month: month(@params[:to_month]),
                                                                                  targets: Array(@params[:targets]).map(&:to_s)))
      raise Error, "Pick the first month" unless charge.from_month
      raise Error, "The first month cannot be in the past" if charge.from_month < Date.current.beginning_of_month

      charge.save!
      bills = FareTables.bill_months(@year, table)
      last = charge.kind == "once" ? charge.from_month : charge.to_month
      warning = bills.none? { |m| m >= charge.from_month && (last.nil? || m <= last) } ? "No bill falls in these months, so no one is charged yet" : nil
      [ charge, warning ]
    end

    private

    def month(v)
      return nil if v.blank?

      Date.strptime(v.to_s[0, 7], "%Y-%m")
    rescue Date::Error
      raise Error, "Months must look like 2026-11"
    end
  end
end

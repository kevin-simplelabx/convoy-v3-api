# The daily drafting (port of fiAuto): for each school year with locked Bus Fares, the coming billing period is drafted
# once its draft day has come (the due date less the draft days of Finance Settings), unless it was drafted already.
# A period whose bill month has passed is left alone. Returns the runs made.
module SchoolBills
  class Auto < ApplicationService
    def initialize(today: Date.current)
      @today = today
    end

    def call
      days = FinanceSetting.current.school_bill_draft_days
      years = AcademicYear.where(ends_on: @today..).includes(:school, fare_table: :academic_year, setup_locks: []).select { it.fare_table&.locked? }
      done = SchoolBillRun.where(academic_year: years).pluck(:academic_year_id, :period_index).to_set
      years.filter_map do |y|
        i = SchoolBills.current_index(y, @today)
        month = FareTables.bill_months(y, y.fare_table)[i]
        next if month.nil? || month < @today.beginning_of_month || done.include?([ y.id, i ])

        start = y.fare_table.cycle == "month" ? month : (FareTables.periods(y, y.fare_table)[i][:starts_on] || month)
        due = SchoolBills.due_on(y.school.policy_versions.in_use_on(@today), start)
        next if @today < due - days

        Run.call(y, i)
      rescue ApplicationService::Error => e
        Rails.logger.info("School bills not drafted for #{y.school.name} AY #{y.key}: #{e.message}")
        nil
      end
    end
  end
end

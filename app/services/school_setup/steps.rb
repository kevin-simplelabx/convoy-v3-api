# Year Setup strip and Summary for an academic year: the 7 steps (done = saved and locked; Policy = a version published)
# and Holidays (always editable).
module SchoolSetup
  class Steps
    STEPS = [
      [ "levels", "School Levels", :school ], [ "calendar", "Terms & Semesters", :year ], [ "sessions", "Bus Sessions", :year ],
      [ "fares", "Bus Fares", :year ], [ "policy", "Payment & Refund Policy", :school ], [ "attendants", "Bus Attendants", :school ],
      [ "operator_pay", "Operator Pay", :school ]
    ].freeze
    PENDING = [].freeze

    def initialize(year)
      @year = year
      @school = year.school
      @locks = SetupLock.where(school: @school).where(academic_year_id: [ nil, year.id ]).includes(:locked_by).to_a
    end

    def call
      steps = STEPS.each_with_index.map do |(key, label, scope), i|
        lock = @locks.find { |l| l.section == key && (scope == :year ? l.academic_year_id == @year.id : l.academic_year_id.nil?) }
        done = key == "policy" ? @school.policy_versions.exists? : lock.present?
        { number: i + 1, key:, label:, scope:, available: !PENDING.include?(key), done:,
          locked_at: lock&.locked_at, locked_by: lock&.locked_by&.name }
      end
      steps << { number: 8, key: "holidays", label: "Holidays & Special Days", scope: :year, available: true, done: nil, always_editable: true }
      { year: @year.key, steps:, done: steps.count { it[:done] }, total: STEPS.size, complete: steps.first(STEPS.size).all? { it[:done] } }
    end
  end
end

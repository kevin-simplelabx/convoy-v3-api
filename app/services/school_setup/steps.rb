# Year Setup strip and Summary: the 7 steps (done = saved and locked; Policy = a version in use today, the rule Registration
# uses) with the strip's one-line `detail` (HTML ayStripVals), and Holidays (always editable). Without a year (a school
# that has none yet) the year steps are not done and `year` is nil.
module SchoolSetup
  class Steps
    STEPS = [
      [ "levels", "School Levels", :school ], [ "calendar", "Terms & Semesters", :year ], [ "sessions", "Bus Sessions", :year ],
      [ "fares", "Bus Fares", :year ], [ "policy", "Payment & Refund Policy", :school ], [ "attendants", "Bus Attendants", :school ],
      [ "operator_pay", "Operator Pay", :school ]
    ].freeze
    PENDING = [].freeze
    PAYER = { "parents" => "Parents pay", "bus" => "School pays per bus", "school" => "School pays per rider" }.freeze
    NEEDS = { "statutory" => "Statutory only", "all" => "All buses" }.freeze

    def initialize(year, school: year&.school, today: Date.current)
      @year = year
      @school = school
      @today = today
      @locks = SetupLock.where(school:).where(academic_year_id: [ nil, year&.id ]).includes(:locked_by).to_a
    end

    def call
      calendar_ok = lock_for("calendar", :year).present? && @year&.terms&.any?
      steps = STEPS.each_with_index.map do |(key, label, scope), i|
        lock = lock_for(key, scope)
        policy = SchoolPolicyVersion.current_for(@school.policy_versions, @today) if key == "policy"
        done = key == "policy" ? policy.present? : lock.present?
        { number: i + 1, key:, label:, scope:, available: !PENDING.include?(key), done:, detail: detail(key, lock, policy, calendar_ok),
          locked_at: lock&.locked_at, locked_by: lock&.locked_by&.name }
      end
      steps << { number: 8, key: "holidays", label: "Holidays & Special Days", scope: :year, available: true, done: nil, always_editable: true,
                 detail: @year && calendar_ok ? "#{@year.holidays.size} holidays, #{@year.special_days.size} special days" : "Needs the calendar first" }
      { year: @year&.key, steps:, done: steps.count { it[:done] }, total: STEPS.size, complete: steps.first(STEPS.size).all? { it[:done] } }
    end

    private

    def lock_for(key, scope)
      @locks.find { |l| l.section == key && (scope == :year ? @year && l.academic_year_id == @year.id : l.academic_year_id.nil?) }
    end

    def locked(lock) = "Locked#{" #{lock.locked_at.strftime('%d/%m/%Y')}" if lock.locked_at}"

    def detail(key, lock, policy, calendar_ok)
      case key
      when "levels" then levels(lock)
      when "calendar" then lock && calendar_ok ? locked(lock) : @year ? "Year setup not saved" : "Not started"
      when "sessions" then lock ? locked(lock) : calendar_ok ? "Not set up yet" : "Needs the calendar first"
      when "fares" then lock ? "#{locked(lock)}. #{PAYER[@year.fare_table&.payer || 'parents']}" : calendar_ok ? "Not set up yet" : "Needs the calendar first"
      when "policy" then policy ? "Version #{policy.version} from #{policy.effective_on.strftime('%d/%m/%Y')}" : "Not set up yet"
      when "attendants" then lock ? "#{locked(lock)}. #{attendants}" : "Not set up yet"
      when "operator_pay" then lock ? locked(lock) : "Not set up yet"
      end
    end

    def levels(lock)
      list = @school.levels
      return list.any? ? "Saved, not locked" : "Not set up yet" unless lock && list.any?

      "#{list.size} #{'level'.pluralize(list.size)}#{", #{list.first.name} to #{list.last.name}" if list.size > 1}"
    end

    def attendants
      policy = @school.attendant_policy
      NEEDS[policy&.needs || "statutory"] || "#{policy.sizes.size} bus sizes"
    end
  end
end

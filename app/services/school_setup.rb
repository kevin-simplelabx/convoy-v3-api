# School Bus Year Setup steps: Save & Lock and Unlock to Edit (setup_locks), and the guard that stops changes to a
# locked step. Typing the year key or UNLOCK before unlocking is the screen's job.
module SchoolSetup
  LABELS = { "calendar" => "Terms & Semesters", "sessions" => "Bus Sessions", "levels" => "School Levels", "attendants" => "Bus Attendants",
             "fares" => "Bus Fares", "operator_pay" => "Operator Pay" }.freeze

  module_function

  def locked?(school:, section:, year: nil) = find(school, year, section).present?

  def ensure_unlocked!(school:, section:, year: nil)
    return unless locked?(school:, year:, section:)

    raise ApplicationService::Error, "#{LABELS[section.to_s]} is locked. Unlock to edit"
  end

  def lock!(school:, section:, user:, year: nil)
    find(school, year, section) || SetupLock.create!(school:, academic_year: year, section:, locked_at: Time.current, locked_by: user)
  end

  def unlock!(school:, section:, year: nil)
    lock = find(school, year, section) or raise ApplicationService::Error, "#{LABELS[section.to_s]} is not locked"
    lock.destroy!
  end

  def find(school, year, section) = SetupLock.find_by(school:, academic_year: year, section: section.to_s)
end

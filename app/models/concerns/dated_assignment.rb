# A driver's pay scheme / vehicle type from starts_on to ends_on (nil = open). Rows of one driver never overlap:
# after each change the rows are re-cut so each ends the day before the next one starts (DatedAssignment.recut!).
# A start date can go back at most a month.
module DatedAssignment
  extend ActiveSupport::Concern

  BACKDATE = 1.month

  included do
    include TenantScoped
    audited associated_with: :driver

    belongs_to :driver

    validates :starts_on, presence: true, uniqueness: { scope: :driver_id, message: "already has an assignment" }
    validate :start_not_too_early, if: -> { starts_on && will_save_change_to_starts_on? }
    validate { errors.add(:ends_on, "is before the start date") if starts_on && ends_on && ends_on < starts_on }

    scope :on, ->(date) { where(starts_on: ..date).where("ends_on IS NULL OR ends_on >= ?", date) }
  end

  class_methods do
    def min_start = Date.current - BACKDATE

    # Each row ends the day before the next one starts (when open or overlapping).
    def recut!(driver_id)
      rows = where(driver_id:).order(:starts_on).to_a
      rows.each_cons(2) do |a, b|
        a.update_columns(ends_on: b.starts_on - 1) if a.ends_on.nil? || a.ends_on >= b.starts_on # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  # upcoming | current | ended
  def tag(today = Date.current)
    return "upcoming" if starts_on > today

    ends_on && ends_on < today ? "ended" : "current"
  end

  private

  def start_not_too_early
    errors.add(:starts_on, "can go back up to 1 month, to #{self.class.min_start.strftime('%-d %b %Y')}") if starts_on < self.class.min_start
  end
end

# A school's academic year: the list row, and (view :detail) its terms with school days, CCA periods, holidays and
# special days, and whether the calendar is locked.
class AcademicYearBlueprint < ApplicationBlueprint
  fields :key, :start_year, :start_month, :starts_on, :ends_on, :structure, :period_count, :operating_days, :cca_same_as_terms
  field(:period_label) { |y| y.period_label }
  field(:started) { |y| y.started? }
  field(:calendar_locked) do |y|
    lock = y.lock_of(:calendar)
    lock && { at: lock.locked_at, by: lock.locked_by&.name }
  end

  view :detail do
    field(:terms) do |y|
      y.terms.map do |t|
        { position: t.position, label: "#{y.period_label} #{t.position}", starts_on: t.starts_on, ends_on: t.ends_on,
          school_days: y.school_days_between(t.starts_on, t.ends_on),
          cca_starts_on: y.cca_same_as_terms ? t.starts_on : t.cca_starts_on, cca_ends_on: y.cca_same_as_terms ? t.ends_on : t.cca_ends_on }
      end
    end
    field(:school_days) { |y| y.school_days }
    field(:holidays) do |y|
      y.holidays.map do |h|
        { id: h.id, name: h.name, starts_on: h.starts_on, ends_on: h.ends_on, public_holiday: h.public_holiday_id.present?,
          operating_days_off: (h.starts_on..h.ends_on).count { |d| y.operating_days.include?(d.cwday) } }
      end
    end
    field(:operating_days_off) do |y|
      y.holidays.flat_map { |h| (h.starts_on..h.ends_on).to_a }.uniq.count { |d| d.between?(y.starts_on, y.ends_on) && y.operating_days.include?(d.cwday) }
    end
    field(:special_days) do |y|
      y.special_days.map { |d| { id: d.id, date: d.date, kind: d.kind, time: d.time_hm, description: d.description } }
    end
  end
end

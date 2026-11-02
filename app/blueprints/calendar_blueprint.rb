class CalendarBlueprint < ApplicationBlueprint
  fields :name, :kind, :observed_holidays
  field(:morning_time) { |c| c.morning_time_hm }
  field(:afternoon_time) { |c| c.afternoon_time_hm }
  # Pass trips_count: { calendar_id => n } (index) for "N trips use it".
  field(:trips_count, if: ->(_name, _c, options) { options.key?(:trips_count) }) { |c, options| options[:trips_count][c.id].to_i }

  # Pass year: to keep only the days touching that year.
  view :with_days do
    field(:days) do |c, options|
      days = c.days.sort_by(&:starts_on)
      if (year = options[:year])
        days = days.select { |d| d.starts_on <= Date.new(year, 12, 31) && d.ends_on >= Date.new(year) }
      end
      CalendarDayBlueprint.render_as_hash(days)
    end
  end
end

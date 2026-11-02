class CalendarBlueprint < ApplicationBlueprint
  fields :name, :kind, :observed_holidays
  field(:morning_time) { |c| c.morning_time_hm }
  field(:afternoon_time) { |c| c.afternoon_time_hm }

  view :with_days do
    association :days, blueprint: CalendarDayBlueprint
  end
end

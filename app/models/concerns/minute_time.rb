# Columns holding minutes after midnight accept "HH:MM" and have an _hm reader.
#   minute_time :usual_time, :new_time
module MinuteTime
  extend ActiveSupport::Concern

  class_methods do
    def minute_time(*columns)
      columns.each do |col|
        define_method(:"#{col}=") do |value|
          super(Clock.minutes(value))
        rescue ArgumentError
          @minute_time_errors = (@minute_time_errors || []) << col
          super(nil)
        end
        define_method(:"#{col}_hm") { Clock.hm(self[col]) }
      end

      validate do
        Array(@minute_time_errors).uniq.each { |col| errors.add(col, "must be a time like 07:30") }
      end
    end
  end
end

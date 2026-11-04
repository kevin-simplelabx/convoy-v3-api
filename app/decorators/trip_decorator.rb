class TripDecorator < ApplicationDecorator
  DAY_NAMES = %w[Sun Mon Tue Wed Thu Fri Sat].freeze

  def trip_id = object.trip_id_on(starts_on)

  # Repeat pattern in words: Every day, Every weekday, Weekends, Mon Wed Fri; nil for one-off trips.
  def repeat_text
    return nil unless recurring?
    return "Every day" if days == (0..6).to_a
    return "Every weekday" if days == (1..5).to_a
    return "Weekends" if days == [ 0, 6 ]

    days.map { |d| DAY_NAMES[d] }.join(" ")
  end

  # Service days as the prototype's dayText: "Daily", "Mon to Fri", "Mon, Wed, Fri" (0 = Sunday).
  def self.days_text(days)
    d = days.map(&:to_i).uniq.sort
    return "Daily" if d.size == 7
    return "Mon to Fri" if d == [ 1, 2, 3, 4, 5 ]
    return "Mon to Sat" if d == [ 1, 2, 3, 4, 5, 6 ]

    d.slice_when { |a, b| b != a + 1 }.map { |r| r.size >= 3 ? "#{DAY_NAMES[r.first]} to #{DAY_NAMES[r.last]}" : r.map { DAY_NAMES[it] }.join(", ") }.join(", ")
  end

  def days_text = self.class.days_text(days)

  def ends_next_day = end_time.to_i >= 1440

  # Vehicles required in words: 2 x 23-seater, 1 x 13-seater.
  def vehicles_required_text = vehicle_requirements.map(&:label).join(", ")

  def route_text = [ pick_up&.name, drop_off&.name ].compact.uniq.join(" to ")
end

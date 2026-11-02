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

  def ends_next_day = end_time.to_i >= 1440

  # Vehicles required in words: 2 x 23-seater, 1 x 13-seater.
  def vehicles_required_text = vehicle_requirements.map(&:label).join(", ")

  def route_text = [ pick_up&.name, drop_off&.name ].compact.uniq.join(" to ")
end

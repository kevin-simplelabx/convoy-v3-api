# Save CCA Rides of a school: charged per ride or not, the price (Bus Fares' CCA / ASA per-trip fare when set there),
# the CCA bus days and the seats a day.
module CcaRides
  class SaveSettings < ApplicationService
    def initialize(school, params, user:)
      @school = school
      @p = params
      @user = user
    end

    def call
      s = CcaRides.setting(@school)
      on = ActiveModel::Type::Boolean.new.cast(@p.fetch(:enabled, s.enabled)) || false
      fares = CcaRides.fares_price(@school)
      price = fares || (@p.key?(:price) ? @p[:price].to_d : s.price)
      days = (@p.key?(:days) ? Array(@p[:days]).map(&:to_i) : s.days).select { it.between?(1, 5) }.uniq.sort
      seats = @p.key?(:seats) ? @p[:seats].to_i : s.seats
      if on
        raise Error, "Enter the price per ride" unless price.positive?
        raise Error, "Pick the days the CCA bus runs" if days.empty?
        raise Error, "Enter the seats per day" unless seats.positive?
      end
      s.update!(enabled: on, price: [ price, 0.to_d ].max, days:, seats: [ seats, 1 ].max, saved_by: @user)
      s
    end
  end
end

# Bus Not Running on a CCA bus day (or no school that day): every ride booked then becomes credit for its family, once.
module CcaRides
  class NotRunning < ApplicationService
    def initialize(school, date:, reason:, user:, note: nil)
      @school = school
      @date = date.presence && Date.parse(date.to_s)
      @reason = reason.to_s
      @note = note.to_s.strip
      @user = user
    end

    def call
      raise Error, "Pick the day" unless @date
      raise Error, "The CCA bus is already marked as not running on #{CcaRides.label(@date)}" if @school.cca_off_days.exists?(date: @date)

      rides = @school.cca_bookings.where(date: @date).to_a
      raise Error, "No rides are booked on #{CcaRides.label(@date)}" if rides.empty?

      why = reason
      ApplicationRecord.transaction do
        @school.cca_off_days.create!(date: @date, reason: why, by_name: @user.name, user: @user)
        rides.each do |b|
          @school.cca_credits.create!(family_id: b.family_id, cca_booking: b, child_name: b.child_name, amount: b.price, date: @date, reason: why)
        end
      end
      rides.size
    rescue Date::Error
      raise Error, "Pick the day"
    end

    private

    def reason
      return "No school: #{@note.presence || 'No school'}" if @reason == "no_school"
      return @note.presence || "Not running" if @reason == "other"

      base = WHY.fetch(@reason) { raise Error, "Pick why the bus is not running" }
      @note.present? ? "#{base}: #{@note}" : base
    end
  end
end

# Correct Record: set what a past run really did — outcome (completed / incomplete), the vehicle (fleet vehicle or a
# plate), the driver (driver or a name), and at each stop the arrival, departure, boarded and alighted. A value left
# out or blank stays as it is. A reason is required; each save is logged with the changes, e.g.
# "Stop 1 arrival: N/A to 08:03". Setting a value back to what was recorded clears its correction.
# The run, its GPS trail and its log are never changed.
module TripHistory
  class Correct < ApplicationService
    STOP_FIELDS = { arrived_at: "arrival", departed_at: "departure", boarded: "boarded", alighted: "alighted" }.freeze

    def initialize(occ:, user:, params:, lock_version: nil)
      @occ = occ
      @user = user
      @params = params.to_h.with_indifferent_access
      @lock_version = lock_version
      @items = []
    end

    def call
      raise Error, "Only a run that ran can be corrected" unless @occ.completed?

      @corr = @occ.correction || @occ.build_correction
      if @corr.persisted? && !@lock_version.nil? && @lock_version.to_i != @corr.lock_version
        raise ActiveRecord::StaleObjectError.new(@corr, "update")
      end

      outcome
      vehicle
      driver
      stops
      raise Error, "Nothing has changed" if @items.empty?

      reason = @params[:reason].to_s.strip
      raise Error, "Give the reason for the correction" if reason.blank?

      OccurrenceCorrection.transaction do
        @corr.updated_at = Time.current # children may be all that changed: still bump lock_version
        @corr.save!
        @corr.logs.create!(user: @user, reason:, items: @items)
        Punctuality.call(@occ)
      end
      @corr
    end

    private

    def given?(key) = @params.key?(key) && @params[key].to_s.strip.present?

    def change(label, from, to) = @items << "#{label}: #{from.presence || 'N/A'} to #{to.presence || 'N/A'}"

    def outcome
      return unless given?(:outcome)

      value = @params[:outcome].to_s
      raise Error, "Outcome must be Completed or Incomplete" unless OccurrenceCorrection::OUTCOMES.include?(value)

      now = TripHistory.outcome(@occ)
      return if value == now

      change("Outcome", OUTCOMES.dig(now, :label), OUTCOMES.dig(value, :label))
      @corr.outcome = value == TripHistory.recorded_outcome(@occ) ? nil : value
    end

    def vehicle
      return unless given?(:vehicle_id) || given?(:vehicle_plate)

      if given?(:vehicle_id)
        v = Vehicle.with_discarded.find(@params[:vehicle_id])
        plate = v.plate
      else
        plate = @params[:vehicle_plate].to_s.strip.upcase.gsub(/\s+/, "")
        v = Vehicle.with_discarded.where("upper(plate) = ?", plate).order(:discarded_at).first
      end
      now = TripHistory.vehicle(@occ)[:plate]
      return if plate == now

      change("Vehicle", now, plate)
      recorded = @occ.vehicle&.plate == plate
      @corr.assign_attributes(vehicle: recorded ? nil : v, vehicle_plate: recorded ? nil : plate)
    end

    def driver
      return unless given?(:driver_id) || given?(:driver_name)

      if given?(:driver_id)
        d = Driver.find(@params[:driver_id])
        name = d.name
      else
        name = @params[:driver_name].to_s.squish
        d = Driver.where("lower(name) = lower(?)", name).first
        name = d.name if d
      end
      now = TripHistory.driver_name(@occ)
      return if name == now

      change("Driver", now, name)
      recorded = TripHistory.recorded_driver_name(@occ) == name
      @corr.assign_attributes(driver: recorded ? nil : d, driver_name: recorded ? nil : name)
    end

    def stops
      list = Array(@params[:stops])
      return if list.empty?

      planned = TripHistory.planned_stops(@occ)
      recorded = TripHistory.recorded_stops(@occ)
      list.each do |input|
        input = input.to_h.with_indifferent_access
        pos = Integer(input[:position], exception: false)
        raise Error, "Stop #{input[:position]} isn't on this run" unless pos && planned[pos]

        row = @corr.stop(pos) || @corr.stops.build(position: pos, stop_name: planned[pos][:name])
        STOP_FIELDS.each do |field, label|
          next if input[field].to_s.strip.blank?

          value = parse(field, input[field], pos)
          was = recorded.dig(pos, field)
          now = row[field].nil? ? was : row[field]
          next if value == now

          change("Stop #{pos + 1} #{label}", show(field, now), show(field, value))
          row[field] = value == was ? nil : value
        end
        check_times(row, recorded[pos] || {}, pos)
        row.mark_for_destruction if STOP_FIELDS.keys.all? { |f| row[f].nil? }
      end
    end

    def parse(field, value, pos)
      if %i[arrived_at departed_at].include?(field)
        Clock.minutes(value.to_s.strip)
      else
        n = Integer(value.to_s.strip, exception: false)
        raise Error, "Stop #{pos + 1}: #{STOP_FIELDS[field]} must be a whole number" if n.nil? || n.negative?

        n
      end
    rescue ArgumentError
      raise Error, "Stop #{pos + 1}: #{STOP_FIELDS[field]} must be a time like 08:05"
    end

    def check_times(row, recorded, pos)
      arr = row.arrived_at || recorded[:arrived_at]
      dep = row.departed_at || recorded[:departed_at]
      raise Error, "Stop #{pos + 1}: departure is before arrival" if arr && dep && dep < arr
    end

    def show(field, value) = %i[arrived_at departed_at].include?(field) ? Clock.hm(value) : value&.to_s
  end
end

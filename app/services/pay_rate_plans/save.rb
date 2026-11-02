# HR > Rate Plans: Save / Save and Lock. The plan is sent whole (name, description, vehicle types, periods with their
# days, time ranges and rates) and replaces what was saved. Empty rates are allowed (they pay S$0; Coverage warns).
module PayRatePlans
  class Save < ApplicationService
    def initialize(plan:, params:, user:, lock: false, admin: false)
      @plan = plan
      @params = params
      @user = user
      @lock = lock
      @admin = admin
    end

    def call
      @plan.ensure_unlocked!(admin: @admin) if @plan.persisted?
      check!
      created = @plan.new_record?
      PayRatePlan.transaction do
        @plan.assign_attributes(name: @params[:name], description: @params[:description])
        @plan.save!
        save_vehicle_types
        save_periods
        @plan.log_audit!("Saved: #{summary}") unless created
        @plan.lock!(@user) if @lock
      end
      @plan
    end

    private

    def periods_params = Array(@params[:periods]).map { |p| p.to_h.deep_symbolize_keys }

    def type_ids = Array(@params[:vehicle_type_ids]).compact_blank.map(&:to_i).uniq

    def check!
      raise Error, "Enter a plan name" if @params[:name].to_s.strip.empty?
      raise Error, "Pick at least one vehicle type" if type_ids.empty?
      raise Error, "Add at least one period" if periods_params.empty?
      raise Error, "Name every period" if periods_params.any? { |p| p[:name].to_s.strip.empty? }

      periods_params.each do |p|
        raise Error, "Pick the days for #{p[:name].to_s.strip}" if (PayRatePeriod::DAYS & Array(p[:days]).map(&:to_s)).empty?
        raise Error, "Add a time for #{p[:name].to_s.strip}" if Array(p[:ranges]).empty?
      end
    end

    def save_vehicle_types
      found = VehicleType.where(id: type_ids).pluck(:id)
      raise Error, "Pick vehicle types from the list" if found.size != type_ids.size

      @plan.plan_vehicle_types.where.not(vehicle_type_id: found).delete_all
      (found - @plan.plan_vehicle_types.pluck(:vehicle_type_id)).each { |id| @plan.plan_vehicle_types.create!(vehicle_type_id: id) }
    end

    def save_periods
      @plan.periods.destroy_all
      periods_params.each_with_index do |p, i|
        period = @plan.periods.create!(name: p[:name], days: p[:days], takes_priority: p[:takes_priority] || false, position: i)
        Array(p[:ranges]).each { |r| period.ranges.create!(start_time: r[:start_time], end_time: r[:end_time]) }
        Array(p[:rates]).each do |r|
          next unless type_ids.include?(r[:vehicle_type_id].to_i)

          period.rates.create!(vehicle_type_id: r[:vehicle_type_id], per_trip: r[:per_trip].presence, per_hour: r[:per_hour].presence)
        end
      end
      @plan.periods.reset
    end

    def summary = "#{periods_params.size} #{'period'.pluralize(periods_params.size)}, #{type_ids.size} vehicle #{'type'.pluralize(type_ids.size)}"
  end
end

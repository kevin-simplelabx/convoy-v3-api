# Operator Pay › Save & Lock: the pay scheme, part months, break months and the default prices per bus size.
module OperatorPays
  class Save < ApplicationService
    def initialize(school, params, user:)
      @school = school
      @p = params
      @user = user
    end

    def call
      SchoolSetup.ensure_unlocked!(school: @school, section: :operator_pay)
      paid = Array(@p[:paid_months]).map(&:to_i).select { it.between?(1, 12) }.uniq.sort
      raise Error, "Pick at least one paid month" if @p[:scheme] != "all" && paid.empty?
      if @p[:scheme] == "part" && !(@p[:part_pct].to_s.match?(/\A\d+(\.\d+)?\z/) && @p[:part_pct].to_d <= 100)
        raise Error, "Enter a percentage from 0 to 100"
      end

      SchoolOperatorPay.transaction do
        settings = @school.operator_pay || @school.build_operator_pay
        settings.update!(@p.slice(:scheme, :part_pct, :part_basis, :break_pay, :earn_by, :grace_start_days, :deduct_days).compact
                           .merge(paid_months: paid, break_months: Array(@p[:break_months]).map(&:to_i).select { it.between?(1, 12) }.uniq.sort, updated_by: @user))
        rates
        SchoolSetup.lock!(school: @school, section: :operator_pay, user: @user)
        settings
      end
    end

    private

    def rates
      @school.bus_size_rates.delete_all
      Array(@p[:rates]).each do |r|
        label = SchoolBus::BUS_TYPES.dig(r[:bus_type], :label) || r[:bus_type]
        rider = [ r[:base_price], r[:riders_included], r[:per_rider] ]
        if r[:rider_on] && rider.any?(&:present?) && rider.any?(&:blank?)
          raise Error, "#{label}: enter the base price, riders included and extra per rider"
        end
        raise Error, "#{label}: keep at least one pricing option" unless r[:fixed_on] || r[:rider_on]

        @school.bus_size_rates.create!(r.slice(:bus_type, :fixed_on, :monthly, :rider_on, :base_price, :riders_included, :per_rider, :ba_operator, :ba_us)
                                         .merge(default_mode: r[:fixed_on] && r[:rider_on] ? (r[:default_mode] || "fixed") : (r[:rider_on] ? "rider" : "fixed")))
      end
    end
  end
end

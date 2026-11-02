# HR > Pay Schemes: Save / Save and Lock. The scheme is sent whole: its fields plus route bands, daily volume tiers and
# weekly / monthly target tiers (each list replaces what was saved). Saving a default scheme makes it the only default;
# a company with no default gets this one.
module PaySchemes
  class Save < ApplicationService
    FIELDS = %i[name description is_default scheme_type pay_rate_plan_id basic_salary basic_covers_daily_trips
                basic_covered_daily_trips basic_covered_schedule basic_cover_ph disposal_counts_as_trips has_guarantee
                guaranteed_amount on_top_ph on_top_sat on_top_sun has_post_guarantee_boost post_guarantee_boost_type
                post_guarantee_boost_value has_rejection_penalty rejection_allowed_jobs rejection_fallback_basic
                rejection_keeps_incentives monthly_pay_amount monthly_minimum_type monthly_daily_trips monthly_trips
                monthly_schedule monthly_cover_ph shift_salary shift_start_time shift_end_time shift_overtime_pay_type
                shift_overtime_hourly_rate school_routes_pay school_routes_count school_routes_in_guarantee
                has_daily_volume_incentive daily_volume_in_guarantee has_weekly_target_incentive weekly_target_in_guarantee
                has_monthly_target_incentive monthly_target_in_guarantee].freeze

    def initialize(scheme:, params:, user:, lock: false, admin: false)
      @scheme = scheme
      @params = params
      @user = user
      @lock = lock
      @admin = admin
    end

    def call
      @scheme.ensure_unlocked!(admin: @admin) if @scheme.persisted?
      created = @scheme.new_record?
      PayScheme.transaction do
        @scheme.assign_attributes(@params.slice(*FIELDS, :shift_working_days))
        raise Error, "Pick a rate plan from the list" if @scheme.pay_rate_plan_id && !PayRatePlan.kept.exists?(@scheme.pay_rate_plan_id)

        PayScheme.kept.where.not(id: @scheme.id).update_all(is_default: false) if @scheme.is_default? # rubocop:disable Rails/SkipsModelValidations
        @scheme.save!
        save_lists
        @scheme.update!(is_default: true) unless PayScheme.kept.exists?(is_default: true)
        @scheme.log_audit!("Saved: #{@scheme.type_label}") unless created
        @scheme.lock!(@user) if @lock
      end
      @scheme
    end

    private

    def rows(key) = Array(@params[key]).map { |r| r.to_h.symbolize_keys }

    # Each list sent replaces the saved one; a list left out stays as it is.
    def save_lists
      if @params.key?(:route_bands)
        bands = rows(:route_bands)
        raise Error, "Enter the monthly pay for every route band" if bands.any? { |b| b[:monthly_amount].blank? }

        @scheme.route_bands.delete_all
        bands.sort_by { |b| b[:up_to_minutes].presence&.to_i || Float::INFINITY }.each_with_index do |b, i|
          @scheme.route_bands.create!(up_to_minutes: b[:up_to_minutes].presence&.to_i&.clamp(1..), monthly_amount: b[:monthly_amount], position: i)
        end
      end
      replace(:volume_tiers, @scheme.volume_tiers, %i[from_trip to_trip boost_type boost_value]) if @params.key?(:volume_tiers)
      { weekly_tiers: "weekly", monthly_tiers: "monthly" }.each do |key, period|
        next unless @params.key?(key)

        @scheme.target_tiers.where(period:).delete_all
        rows(key).each_with_index { |r, i| @scheme.target_tiers.create!(r.slice(:target_trips, :pay_as, :amount).merge(period:, position: i)) }
      end
      @scheme.association(:target_tiers).reset
    end

    def replace(key, relation, attrs)
      relation.delete_all
      rows(key).each_with_index { |r, i| relation.create!(r.slice(*attrs).merge(position: i)) }
      relation.reset
    end
  end
end

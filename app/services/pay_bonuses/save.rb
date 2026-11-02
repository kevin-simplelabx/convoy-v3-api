# HR > Bonuses: Save / Save and Lock. The bonus is sent whole (fields, tiers, split payments, eligible schemes and
# drivers, drivers signed up by hand, excluded days); each list sent replaces the saved one.
module PayBonuses
  class Save < ApplicationService
    FIELDS = %i[name description plan_type frequency starts_on last_period_on payout_type payout_delay_months requires_sign_up
                sign_up_from sign_up_to terms overlap_daily overlap_weekly overlap_monthly].freeze

    def initialize(bonus:, params:, user:, lock: false, admin: false)
      @bonus = bonus
      @params = params
      @user = user
      @lock = lock
      @admin = admin
    end

    def call
      @bonus.ensure_unlocked!(admin: @admin) if @bonus.persisted?
      created = @bonus.new_record?
      PayBonus.transaction do
        @bonus.assign_attributes(@params.slice(*FIELDS))
        @bonus.all_schemes = Array(@params[:scheme_ids]).compact_blank.empty? if @params.key?(:scheme_ids)
        check!
        @bonus.save!
        save_lists
        @bonus.log_audit!("Saved: #{@bonus.type_label}, #{@bonus.frequency.humanize.downcase}") unless created
        @bonus.lock!(@user) if @lock
      end
      @bonus
    end

    private

    def rows(key) = Array(@params[key]).map { |r| r.to_h.symbolize_keys }

    def check!
      raise Error, "Enter a bonus name" if @bonus.name.blank?
      raise Error, "Add at least one tier" if @params.key?(:tiers) ? rows(:tiers).empty? : @bonus.tiers.empty?
      if @bonus.paid_split_trenches? && @params.key?(:payments)
        sum = rows(:payments).sum { |p| p[:percentage].to_i }
        raise Error, "The split payments add up to #{sum}%. They must add up to 100%" if sum != 100
      end
      if @bonus.requires_sign_up?
        raise Error, "Set the sign-up dates" if @bonus.sign_up_from.nil? || @bonus.sign_up_to.nil?
        raise Error, "Sign-up ends before it starts" if @bonus.sign_up_to < @bonus.sign_up_from
      end
      raise Error, "The last period is before the first" if @bonus.last_period_on && @bonus.starts_on && @bonus.last_period_on < @bonus.starts_on
      raise Error, "On-time and attendance bonuses run monthly or longer" if !@bonus.trip_target? && (@bonus.every_daily? || @bonus.every_weekly?)
    end

    def save_lists
      replace(@bonus.tiers, rows(:tiers), %i[target_trips metric_min metric_max pay_as amount points]) if @params.key?(:tiers)
      replace(@bonus.payments, rows(:payments), %i[percentage months_after]) if @params.key?(:payments)
      replace(@bonus.excluded_periods, rows(:excluded_periods), %i[name starts_on ends_on], position: false) if @params.key?(:excluded_periods)
      if @params.key?(:scheme_ids)
        @bonus.bonus_schemes.delete_all
        PayScheme.kept.where(id: Array(@params[:scheme_ids]).compact_blank).find_each { |s| @bonus.bonus_schemes.create!(pay_scheme: s) }
      end
      drivers(:eligible_driver_ids, "eligible")
      drivers(:signed_up_driver_ids, "signed_up")
    end

    def drivers(key, role)
      return unless @params.key?(key)

      ids = Driver.kept.where(id: Array(@params[key]).compact_blank).pluck(:id)
      @bonus.bonus_drivers.where(role:).where.not(driver_id: ids).delete_all
      (ids - @bonus.bonus_drivers.where(role:).pluck(:driver_id)).each do |id|
        @bonus.bonus_drivers.create!(driver_id: id, role:, **(role == "signed_up" ? { signed_up_at: Time.current, signed_up_by: @user } : {}))
      end
    end

    def replace(relation, list, attrs, position: true)
      relation.delete_all
      list.each_with_index { |r, i| relation.create!(r.slice(*attrs).merge(position ? { position: i } : {})) }
      relation.reset
    end
  end
end

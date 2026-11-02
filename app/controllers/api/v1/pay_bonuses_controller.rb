# HR > Bonuses: list, bonus, Save / Save and Lock (the whole bonus), Lock / Unlock, Delete, and the period options.
module Api
  module V1
    class PayBonusesController < BaseController
      def index
        authorize PayBonus
        render_list policy_scope(PayBonus).kept.includes(:locked_by).order(starts_on: :desc, name: :asc), PayBonusBlueprint
      end

      def show
        render_bonus authorize(find_bonus)
      end

      # POST /pay/bonuses { bonus: {...}, lock: true }
      def create
        authorize PayBonus
        render_bonus PayBonuses::Save.call(bonus: PayBonus.new, params: bonus_params, user: current_user, lock: lock?), status: :created
      end

      def update
        bonus = authorize find_bonus
        render_bonus PayBonuses::Save.call(bonus:, params: bonus_params, user: current_user, lock: lock?, admin: policy(bonus).admin?)
      end

      def destroy
        bonus = authorize find_bonus
        bonus.ensure_unlocked!(admin: policy(bonus).admin?)
        bonus.discard!
        bonus.audits.create!(action: "destroy", audited_changes: { "name" => bonus.name })
        head :no_content
      end

      def lock
        bonus = authorize find_bonus
        bonus.lock!(current_user) unless bonus.locked?
        render_bonus bonus
      end

      def unlock
        bonus = authorize find_bonus
        bonus.unlock! if bonus.locked?
        render_bonus bonus
      end

      # GET /pay/bonuses/periods?frequency=weekly — First / Last Period options.
      def periods
        authorize PayBonus, :index?
        render json: { data: Pay::BonusPeriods.call(frequency: params.require(:frequency)) }
      end

      private

      def find_bonus = policy_scope(PayBonus).kept.find(params[:id])

      def lock? = ActiveModel::Type::Boolean.new.cast(params[:lock]) || false

      def bonus_params
        params.expect(bonus: [ *PayBonuses::Save::FIELDS, { scheme_ids: [], eligible_driver_ids: [], signed_up_driver_ids: [] },
                               { tiers: [ %i[target_trips metric_min metric_max pay_as amount points] ] },
                               { payments: [ %i[percentage months_after] ] }, { excluded_periods: [ %i[name starts_on ends_on] ] } ])
      end

      def render_bonus(bonus, status: :ok)
        bonus = PayBonus.includes(:tiers, :payments, :bonus_schemes, :bonus_drivers, :excluded_periods, :locked_by).find(bonus.id)
        render_data bonus, PayBonusBlueprint, view: :detail, status:
      end
    end
  end
end

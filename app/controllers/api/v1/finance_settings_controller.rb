# Finance > Finance Settings: GST, payment details, operator pay run approval, what documents show, document prefixes;
# Save / Save & Lock, Lock, Unlock (Admin).
module Api
  module V1
    class FinanceSettingsController < BaseController
      def show
        authorize :finance, :settings?
        render_settings
      end

      # PATCH /finance/settings { settings: {..., approvers: [{ user_id, can_prepare, can_approve }]}, lock: true }
      def update
        authorize :finance, :update_settings?
        Finance::SaveSettings.call(settings:, params: settings_params, user: current_user, lock: ActiveModel::Type::Boolean.new.cast(params[:lock]))
        render_settings
      end

      def lock
        authorize :finance, :update_settings?
        settings.update!(locked_at: Time.current, locked_by: current_user) unless settings.locked?
        render_settings
      end

      def unlock
        authorize :finance, :unlock?
        settings.update!(locked_at: nil, locked_by: nil)
        render_settings
      end

      private

      def settings = @settings ||= FinanceSetting.current

      def settings_params
        params.expect(settings: [ *Finance::SaveSettings::FIELDS, { approvers: [ %i[user_id can_prepare can_approve] ] } ])
      end

      def render_settings
        s = settings.reload
        active = User.kept.active.where(company_id: s.company_id).count
        render json: { data: FinanceSettingBlueprint.render_as_hash(s, active_users: active) }
      end
    end
  end
end

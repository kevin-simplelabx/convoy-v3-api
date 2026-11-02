# HR > Pay Schemes: list, scheme, Save / Save and Lock (the whole scheme), Lock / Unlock, Delete.
module Api
  module V1
    class PaySchemesController < BaseController
      def index
        authorize PayScheme
        render_list policy_scope(PayScheme).kept.includes(:locked_by).order(:name), PaySchemeBlueprint
      end

      def show
        render_scheme authorize(find_scheme)
      end

      # POST /pay/schemes { scheme: {...}, lock: true }
      def create
        authorize PayScheme
        render_scheme PaySchemes::Save.call(scheme: PayScheme.new, params: scheme_params, user: current_user, lock: lock?), status: :created
      end

      def update
        scheme = authorize find_scheme
        render_scheme PaySchemes::Save.call(scheme:, params: scheme_params, user: current_user, lock: lock?, admin: policy(scheme).admin?)
      end

      def destroy
        scheme = authorize find_scheme
        scheme.ensure_unlocked!(admin: policy(scheme).admin?)
        raise ApplicationService::Error, "Keep at least one pay scheme" if PayScheme.kept.count == 1
        raise ApplicationService::Error, "Make another scheme the default first" if scheme.is_default?

        scheme.discard!
        scheme.audits.create!(action: "destroy", audited_changes: { "name" => scheme.name })
        head :no_content
      end

      def lock
        scheme = authorize find_scheme
        scheme.lock!(current_user) unless scheme.locked?
        render_scheme scheme
      end

      def unlock
        scheme = authorize find_scheme
        scheme.unlock! if scheme.locked?
        render_scheme scheme
      end

      private

      def find_scheme = policy_scope(PayScheme).kept.find(params[:id])

      def lock? = ActiveModel::Type::Boolean.new.cast(params[:lock]) || false

      def scheme_params
        params.expect(scheme: [ *PaySchemes::Save::FIELDS, { shift_working_days: [] },
                                { route_bands: [ %i[up_to_minutes monthly_amount] ] },
                                { volume_tiers: [ %i[from_trip to_trip boost_type boost_value] ] },
                                { weekly_tiers: [ %i[target_trips pay_as amount] ] },
                                { monthly_tiers: [ %i[target_trips pay_as amount] ] } ])
      end

      def render_scheme(scheme, status: :ok)
        scheme = PayScheme.includes(:rate_plan, :locked_by, :route_bands, :volume_tiers, :target_tiers).find(scheme.id)
        render_data scheme, PaySchemeBlueprint, view: :detail, status:
      end
    end
  end
end

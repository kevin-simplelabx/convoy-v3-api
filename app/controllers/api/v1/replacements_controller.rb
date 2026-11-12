# Replacements: the Replace form (trip drawer: occurrence_id), Driver Away / Vehicle Down (vehicle panel: a date range
# on original_vehicle_id), the Replacements list, and a preview of what a replacement would do before saving.
module Api
  module V1
    class ReplacementsController < BaseController
      INCLUDES = [ :trip, :original_vehicle, :vehicle, :driver, :operator_driver, :created_by, { notifications: :sent_by } ].freeze
      FIELDS = %i[kind scope original_vehicle_id starts_on ends_on vehicle_id driver_id operator_driver_id driver_name
                  driver_phone handover_stop handover_time eta pay_split original_share arranged_by deduction premium reason].freeze

      # GET /replacements?from=&vehicle_id= — from 30 days ago by default, earliest first.
      def index
        authorize Replacement
        from = params[:from].present? ? Date.parse(params[:from]) : Date.current - 30
        scope = policy_scope(Replacement).where(ends_on: from..).includes(*INCLUDES).order(:starts_on, :created_at)
        scope = scope.where(original_vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
        scope = scope.where(scope: params[:scope]) if params[:scope].present?
        render_page scope, ReplacementBlueprint, meta: { active: scope.where(ends_on: Date.current..).count }
      end

      def show
        render_data authorize(find), ReplacementBlueprint
      end

      # GET /replacements/preview?occurrence_id=&replacement[...] — runs touched, message, who gets the trip value, deduction, who would be notified.
      def preview
        authorize Replacement
        rep = Replacement.new(rep_params)
        occ = occurrence
        rep.attach_run(occ) if occ
        rep.validate
        affected = rep.original_vehicle_id ? Replacements::Affected.runs(rep) : TripOccurrence.none
        runs = affected.order(:starts_at).limit(200)
        d = rep.decorate
        render json: {
          data: {
            affected: runs.size, runs: runs.map { |o| { id: o.id, trip_label: o.trip_label, date: o.date, start_time: o.start_time_hm } },
            message: rep.original_vehicle_id ? d.wording.message : nil, pay_text: rep.original_vehicle_id ? d.pay_text : nil,
            operator: rep.original_vehicle&.operator&.slice(:id, :name), deduction_default: rep.original_vehicle_id ? d.default_deduction : 0,
            notify: Replacements::NotifyAudiences.call(affected), errors: rep.errors.full_messages
          }
        }
      end

      # POST { replacement: {...}, occurrence_id, notify: { audiences: [guests, parents], channels: [email, push] } }
      def create
        rep = authorize Replacement.new
        save(rep, :created)
      end

      def update
        save(authorize(find), :ok)
      end

      def destroy
        Replacements::Remove.call(authorize(find))
        head :no_content
      end

      private

      def find = policy_scope(Replacement).includes(*INCLUDES).find(params[:id])

      def occurrence = params[:occurrence_id].presence && TripOccurrence.find(params[:occurrence_id])

      def rep_params = params.fetch(:replacement, {}).permit(*FIELDS)

      def save(rep, status)
        notify = params[:notify].presence && params.require(:notify).permit(audiences: [], channels: [])
        Replacements::Save.call(replacement: rep, attributes: rep_params, user: current_user, occurrence:, notify:)
        render_data policy_scope(Replacement).includes(*INCLUDES).find(rep.id), ReplacementBlueprint, status:
      end
    end
  end
end

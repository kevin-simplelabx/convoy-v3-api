module Api
  module V1
    class AttendantsController < BaseController
      before_action :require_company!
      before_action -> { require_permission!("vehicles") }, only: [ :create, :destroy ]

      # GET /api/v1/attendants
      def index
        attendants = current_company.attendants.order(:name)
        render json: AttendantBlueprint.render_as_hash(attendants)
      end

      # POST /api/v1/attendants
      def create
        p = attendant_params
        if p[:id].present?
          attendant = current_company.attendants.find_by(id: p[:id])
          if attendant
            attendant.update!(p.except(:id))
          else
            attendant = current_company.attendants.create!(p.except(:id))
          end
        else
          attendant = current_company.attendants.create!(p)
        end
        render json: AttendantBlueprint.render_as_hash(attendant)
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.record.errors.full_messages.first)
      end

      # DELETE /api/v1/attendants/:id
      def destroy
        attendant = current_company.attendants.find_by(id: params[:id])
        return render_error("Attendant not found", :not_found) unless attendant
        attendant.destroy!
        render json: { ok: true }
      end

      private

      def attendant_params
        params.permit(:id, :name, :contact, :notes)
      end
    end
  end
end

# Insurance files of a vehicle's current policy: add (upload or attach a read; up to 5), change kind, remove.
module Api
  module V1
    class VehicleInsuranceDocumentsController < BaseController
      before_action :set_vehicle

      # POST /vehicles/:vehicle_id/insurance_documents { file | document_read_id, kind }
      def create
        authorize VehicleInsuranceDocument
        read = params[:document_read_id].presence && policy_scope(DocumentRead).find(params[:document_read_id])
        result = VehicleDocuments::AddInsuranceDocument.call(vehicle: @vehicle, file: params[:file], document_read: read,
                                                             kind: params[:kind])
        render json: {
          data: VehicleInsuranceDocumentBlueprint.render_as_hash(result.document.decorate),
          meta: { filled: result.filled, policy_id: result.document.vehicle_insurance_policy_id }
        }, status: :created
      end

      def update
        document = authorize find_document
        document.update!(params.expect(vehicle_insurance_document: [ :kind ]))
        render_data document, VehicleInsuranceDocumentBlueprint
      end

      def destroy
        authorize(find_document).destroy!
        head :no_content
      end

      private

      def set_vehicle
        @vehicle = Vehicle.kept.find(params[:vehicle_id])
      end

      def find_document
        VehicleInsuranceDocument.joins(:policy).where(vehicle_insurance_policies: { vehicle_id: @vehicle.id }).find(params[:id])
      end
    end
  end
end

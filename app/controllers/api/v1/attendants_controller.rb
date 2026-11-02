module Api
  module V1
    class AttendantsController < BaseController
      def index
        authorize Attendant
        render_page policy_scope(Attendant).kept.ransack(ransack_params).result.order(:name), AttendantBlueprint
      end

      def create
        attendant = authorize Attendant.new(attendant_params)
        attendant.save!
        render_data attendant, AttendantBlueprint, status: :created
      end

      def update
        attendant = authorize Attendant.kept.find(params[:id])
        attendant.update!(attendant_params)
        render_data attendant, AttendantBlueprint
      end

      def destroy
        authorize(Attendant.kept.find(params[:id])).discard!
        head :no_content
      end

      private

      def attendant_params = params.expect(attendant: %i[name phone photo remove_photo notes])
    end
  end
end

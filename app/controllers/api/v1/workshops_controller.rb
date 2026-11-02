# Workshops window: name, address, phone. One used by a visit can't be deleted.
module Api
  module V1
    class WorkshopsController < BaseController
      def index
        authorize Workshop
        render json: { data: policy_scope(Workshop).order(:name).map { |w| w.slice(:id, :name, :address, :phone) } }
      end

      def create
        w = authorize Workshop.new(workshop_params)
        w.save!
        render json: { data: w.slice(:id, :name, :address, :phone) }, status: :created
      end

      def update
        w = authorize Workshop.find(params[:id])
        w.update!(workshop_params)
        render json: { data: w.slice(:id, :name, :address, :phone) }
      end

      def destroy
        w = authorize Workshop.find(params[:id])
        return render_error(:unprocessable_content, "#{w.name} has visits, so it can't be deleted") if w.visits.exists?

        w.destroy!
        head :no_content
      end

      private

      def workshop_params = params.expect(workshop: %i[name address phone])
    end
  end
end

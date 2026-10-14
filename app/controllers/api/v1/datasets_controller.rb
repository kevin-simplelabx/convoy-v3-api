module Api
  module V1
    class DatasetsController < BaseController
      before_action :require_company!
      before_action :load_school
      before_action -> { require_permission!("schools") }, only: [ :create, :destroy ]

      # GET /api/v1/schools/:school_id/datasets
      def index
        datasets = @school.datasets.order(effective_from: :desc)
        render json: DatasetBlueprint.render(datasets)
      end

      # POST /api/v1/schools/:school_id/datasets
      def create
        p = params.permit(:effectiveFrom, :fileName)
        unless p[:effectiveFrom] =~ /\A\d{4}-\d{2}-\d{2}\z/
          return render_error("Effective From must be a date")
        end
        return render_error("No rows") unless params[:rows].is_a?(Array)

        dataset = @school.datasets.create!(
          effective_from: p[:effectiveFrom],
          file_name:      p[:fileName].presence || "upload.csv",
          uploaded_by:    current_user.name,
          rows:           params[:rows]
        )
        render json: { id: dataset.id, count: dataset.rows.length }, status: :created
      end

      # DELETE /api/v1/datasets/:id
      def destroy
        dataset = Dataset.joins(:school).find_by(id: params[:id], schools: { company_id: current_company.id })
        dataset&.destroy
        render json: { ok: true }
      end

      private

      def load_school
        @school = current_company.schools.find_by(id: params[:school_id])
        render_error("School not found", :not_found) unless @school
      end
    end
  end
end

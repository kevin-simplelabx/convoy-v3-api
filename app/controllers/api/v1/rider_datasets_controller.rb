# School Bus › school › Rider Data: the uploaded rider lists (state on a date), a check of a file before importing it,
# Import (homes placed by OneMap in the background) and Delete.
module Api
  module V1
    class RiderDatasetsController < BaseController
      # GET /schools/:school_id/rider_datasets?date=
      def index
        school = authorize find_school, :show?
        date = day
        list = school.rider_datasets.includes(:uploaded_by)
        render_list list, RiderDatasetBlueprint, date:, in_use: list.in_use_on(date), meta: { date: }
      end

      # GET /schools/:school_id/rider_events?date= — the Plan For calendar: joining / leaving / service change / new rider
      # list by date, and how many changes come in the 30 days after the date.
      def events
        school = authorize find_school, :show?
        list = RiderEvents.new(school).call
        render json: { data: list, meta: { date: day, soon: RiderEvents.soon(list, day) } }
      end

      # POST /schools/:school_id/rider_datasets/preview (multipart file)
      def preview
        authorize find_school, :manage_riders?
        file = params.require(:file)
        result = SchoolRiders::FileReader.call(file.path, File.extname(file.original_filename))
        render json: { data: { riders: result.rows.size, problems: result.errors.size, errors: result.errors.first(50),
                               sample: result.rows.first(5).map { it.except(:line) } } }
      end

      # POST /schools/:school_id/rider_datasets (multipart file, effective_from)
      def create
        school = authorize find_school, :manage_riders?
        dataset, skipped = SchoolRiders::Import.call(school:, file: params[:file], effective_from: day(:effective_from, nil), user: current_user)
        render json: { data: RiderDatasetBlueprint.render_as_hash(dataset.decorate), meta: { skipped: skipped.first(50), skipped_count: skipped.size } },
               status: :created
      end

      def destroy
        school = authorize find_school, :manage_riders?
        school.rider_datasets.find(params[:id]).destroy!
        head :no_content
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def day(key = :date, fallback = Date.current)
        params[key].present? ? Date.iso8601(params[key]) : fallback
      rescue Date::Error
        raise ApplicationService::Error, "#{key.to_s.humanize} must look like 2026-11-02"
      end
    end
  end
end

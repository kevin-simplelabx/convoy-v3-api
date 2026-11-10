# School Bus › Schools: the list, New School (placed on the map by its postal code), the school record and its Route Labels.
module Api
  module V1
    class SchoolsController < BaseController
      def index
        authorize School
        date = params[:date].present? ? Date.iso8601(params[:date]) : Date.current
        render_list policy_scope(School).includes(:client, :rider_datasets).order(:name), SchoolBlueprint, date:
      rescue Date::Error
        raise ApplicationService::Error, "Date must look like 2026-11-02"
      end

      def show
        render_data authorize(find), SchoolBlueprint, view: :record
      end

      def create
        authorize School
        school = Schools::Create.call(params.expect(school: %i[name short_name address postal]))
        render_data school, SchoolBlueprint, view: :record, status: :created
      end

      # PUT /schools/:id/route_labels { labels: { am: { prefix, start, digits, suffix }, pm: {…}, asa: {…} } }
      def update_labels
        school = authorize find
        labels = params.expect(labels: [ am: %i[prefix start digits suffix], pm: %i[prefix start digits suffix], asa: %i[prefix start digits suffix] ])
        Schools::SaveLabels.call(school, labels.to_h)
        render_data school, SchoolBlueprint, view: :record
      end

      # GET /schools/:id/setup[?academic_year_id=] — the Year Setup steps for the strip; no year needed (the running, next or latest one).
      def setup
        school = authorize find, :show?
        year = params[:academic_year_id].present? ? school.academic_years.find(params[:academic_year_id]) : AcademicYear.default_for(school)
        render json: { data: SchoolSetup::Steps.new(year, school:).call }
      end

      # POST /schools/:id/unlock { section: levels | attendants }
      def unlock
        section = params.require(:section)
        raise ApplicationService::Error, "Unknown step" unless SetupLock::SCHOOL_SECTIONS.include?(section)

        school = authorize find, section == "operator_pay" ? :money_setup? : :setup?

        SchoolSetup.unlock!(school:, section:)
        render_data school, SchoolBlueprint, view: :record
      end

      private

      def find = policy_scope(School).includes(:client, :route_labels, :rider_datasets).find(params[:id])
    end
  end
end

module Api
  module V1
    class SchoolsController < BaseController
      before_action :require_company!
      before_action -> { require_permission!("schools") }, only: [ :create ]

      # GET /api/v1/schools
      def index
        render json: SchoolBlueprint.render(current_company.schools.order(:name))
      end

      # POST /api/v1/schools
      def create
        p = params.permit(:id, :name, :short, :address, :postal, :lat, :lng)
        return render_error("School name is required") if p[:name].blank?

        school = p[:id].present? ? current_company.schools.find_by(id: p[:id]) : nil
        school ||= current_company.schools.build

        school.assign_attributes(
          name:    p[:name].strip,
          short:   p[:short].to_s,
          address: p[:address].to_s,
          postal:  p[:postal].to_s,
          lat:     p[:lat],
          lng:     p[:lng]
        )
        school.save!
        render json: SchoolBlueprint.render(school), status: school.previously_new_record? ? :created : :ok
      end
    end
  end
end

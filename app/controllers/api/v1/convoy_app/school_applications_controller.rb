# Convoy App › Request School Bus (Bus Service Application, 3 steps): the form, the Review and Estimated Fare step, Submit.
module Api
  module V1
    module ConvoyApp
      class SchoolApplicationsController < SchoolBaseController
        # GET /app/school/apply?school_id= → { school, home, providers: [{ school_id, company, year, window, start, levels, services, cca, ... children }] }
        def new
          render json: { data: ::ConvoyApp::Parents::Form.call(member: current_member, school_id: params.require(:school_id)) }
        end

        # POST /app/school/apply/review { application } → per child legs, start and estimated fare; totals; registration fee
        def review
          render json: { data: ::ConvoyApp::Parents::Submit.call(member: current_member, params: application_params, preview: true) }
        end

        # POST /app/school/apply { application: { school_id, agree, children: [...] } } → 201 [request]
        def create
          reqs = ::ConvoyApp::Parents::Submit.call(member: current_member, params: application_params)
          render json: { data: present_all(reqs) }, status: :created
        end

        private

        def application_params
          params.expect(application: [ :school_id, :agree, { children: [ [ :dependant_id, :level, :student_id, :start_when, :start_on, :fix_why, :fix_note, :service, :cca,
                                                                              :cca_from, { pickup: %i[point postal address], dropoff: %i[point postal address] } ] ] } ])
        end
      end
    end
  end
end

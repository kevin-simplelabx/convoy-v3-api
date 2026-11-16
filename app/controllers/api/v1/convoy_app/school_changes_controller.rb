# Convoy App › Renew for <yr>, Change Service, Stop Bus Service (children who already ride).
module Api
  module V1
    module ConvoyApp
      class SchoolChangesController < SchoolBaseController
        # GET /app/school/changes?kind=renew|svc|stop → { kind, children: [row], mine: [request], from_dates (svc), why (stop) }
        def index
          render json: { data: ::ConvoyApp::Parents::Changes.call(member: current_member, kind: params[:kind]) }
        end

        # POST /app/school/renewals { renewal: { children: [{ dependant_id, level, service, cca }] } } → 201 [request]
        def renew = send_requests(::ConvoyApp::Parents::Renew, params.expect(renewal: [ { children: [ %i[dependant_id level service cca] ] } ]))

        # POST /app/school/service_changes { service_change: { from, children: [{ dependant_id, service, cca }] } } → 201 [request]
        def change = send_requests(::ConvoyApp::Parents::ChangeService, params.expect(service_change: [ :from, { children: [ %i[dependant_id service cca] ] } ]))

        # POST /app/school/stops { stop: { last_on, why, why_note, children: [{ dependant_id }] } } → 201 [request]
        def stop = send_requests(::ConvoyApp::Parents::StopService, params.expect(stop: [ :last_on, :why, :why_note, { children: [ %i[dependant_id] ] } ]))

        private

        def send_requests(service, attrs)
          reqs = service.call(member: current_member, params: attrs)
          render json: { data: present_all(reqs) }, status: :created
        end
      end
    end
  end
end

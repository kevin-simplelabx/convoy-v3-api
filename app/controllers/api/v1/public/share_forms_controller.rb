# Share Form page (public, no sign-in): a hired driver sends the bus, their details and the company they drive for.
# Throttled per IP in config/initializers/rack_attack.rb.
module Api
  module V1
    module Public
      class ShareFormsController < ApplicationController
        include ErrorHandling

        before_action :set_link
        # The page shows the first thing to fix as written ("Enter your name"), not as a full model message.
        rescue_from ActiveRecord::RecordInvalid do |e|
          render_error(:unprocessable_content, e.record.errors.first.message, details: e.record.errors.to_hash, code: "invalid")
        end

        # { company } for the page title ("<company> asked for your bus details").
        def show
          render json: { data: { company: @link.company.name } }
        end

        def create
          ActsAsTenant.with_tenant(@link.company) do
            submission = @link.submissions.create!(submission_params.merge(company: @link.company, submitted_ip: request.remote_ip))
            render json: { data: { id: submission.id, received: true } }, status: :created
          end
        end

        private

        def set_link
          @link = ActsAsTenant.without_tenant { ExternalVehicleShareLink.includes(:company).find_by(token: params[:token]) }
          render_error(:not_found, "This link no longer works. Ask for a new one") unless @link&.live?
        end

        def submission_params
          params.expect(submission: %i[plate seats driver_name driver_phone company_name company_phone paynow])
        end
      end
    end
  end
end

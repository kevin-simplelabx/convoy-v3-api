# Convoy App › Application Status and the replies a parent can give on a request: Withdraw Request, Agree to New Fare /
# Don't Agree.
module Api
  module V1
    module ConvoyApp
      class SchoolRequestsController < SchoolBaseController
        # GET /app/school/requests/:id → request
        def show
          render json: { data: with_request(params[:id]) { present(it) } }
        end

        # POST /app/school/requests/:id/withdraw → request (status Withdrawn)
        def withdraw
          data = with_request(params[:id]) { present(::ConvoyApp::Parents::Withdraw.call(it, account: current_account)) }
          render json: { data: }
        end

        # POST /app/school/requests/:id/agree { yes: true|false } → request (Active, or Not Agreed)
        def agree
          yes = ActiveModel::Type::Boolean.new.cast(params.require(:yes))
          data = with_request(params[:id]) do |req|
            ::BusRequests::Agree.call(req, yes:)
            present(req.reload)
          end
          render json: { data: }
        end
      end
    end
  end
end

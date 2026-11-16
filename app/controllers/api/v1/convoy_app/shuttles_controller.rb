# Convoy App › Shuttles: the employer's route list with the tag chips, My Usual Shuttle and the employer switch.
module Api
  module V1
    module ConvoyApp
      class ShuttlesController < ShuttleBaseController
        # GET /app/shuttles?employer_id=&tag=All|Pinned|<tag> → { employers, employer, usual, tags, tag, routes }
        #   employers = [] when the person has no live staff link (the app shows "Shuttles Come From Your Employer").
        def index
          render json: { data: ::ConvoyApp::Shuttles::RouteList.call(account: current_account, employer_id: params[:employer_id], tag: params[:tag]) }
        end
      end
    end
  end
end

# The portal shell: who is signed in, the organisation picked, what they may do and which rail items show.
module Api
  module V1
    module Portal
      class MeController < AppController
        # GET /portal/me
        def show
          authorize_portal :shell, :show?
          render json: { data: ::Portal::Shell.call(client_user: current_client_user) }
        end
      end
    end
  end
end

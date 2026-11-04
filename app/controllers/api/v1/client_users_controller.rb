# Managed Clients > Client Users (nested under /clients/:client_id): people who sign in to the Client Portal, with their
# role and site access; and the Client Portal roles (Role Permissions window).
module Api
  module V1
    class ClientUsersController < BaseController
      before_action :set_client, except: :roles

      def index
        authorize ClientUser
        render_list @client.users.kept.includes(:sites, :created_by, :created_by_client_user, :team, :manager, :portal_account).order(:name), ClientUserBlueprint
      end

      # GET /client_users/roles
      def roles
        authorize ClientUser
        render json: { data: ClientUser::ROLES.map { |id, r| { id:, label: r[:label], tag: r[:tag], wide: r[:wide] } } }
      end

      # POST /clients/:client_id/users { client_user: { name, title, email, role, site_ids: [] } }
      def create
        authorize ClientUser
        render_user ClientUsers::Save.call(client: @client, params: user_params, actor: current_user), status: :created
      end

      # PATCH /clients/:client_id/users/:id { client_user: { title, role, site_ids: [] } }
      def update
        user = authorize find_user
        render_user ClientUsers::Save.call(client: @client, user:, params: user_params, actor: current_user)
      end

      def destroy
        ClientUsers::Remove.call(user: authorize(find_user))
        head :no_content
      end

      private

      def set_client
        @client = policy_scope(Client).kept.find(params[:client_id])
      end

      def find_user = @client.users.kept.find(params[:id])

      def user_params = params.expect(client_user: [ :name, :title, :email, :role, { site_ids: [] } ])

      def render_user(user, status: :ok)
        render_data user.reload, ClientUserBlueprint, status:
      end
    end
  end
end

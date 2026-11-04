# Client Portal › Settings › Users: the people of the organisation the viewer may see; add, change and remove them
# (roles the viewer may give, the viewer's own sites; see ClientUserAccess#manages?).
module Api
  module V1
    module Portal
      class UsersController < AppController
        INCLUDES = [ :portal_account, :team, :manager, :user_sites, :sites ].freeze

        # GET /portal/users
        def index
          authorize_portal ClientUser
          users = policy_scope([ :portal, ClientUser ]).includes(*INCLUDES).order(:name)
          render json: { data: PortalUserBlueprint.render_as_hash(users, viewer: current_client_user) }
        end

        # POST /portal/users { user: { name, email, role, site_ids: [], team_id, manager_id } }
        def create
          authorize_portal ClientUser
          user = ClientUsers::Save.call(client: current_client, params: params.expect(user: [ :name, :email, :role, :team_id, :manager_id, { site_ids: [] } ]),
                                        actor: current_client_user)
          render_user user, status: :created
        end

        # PATCH /portal/users/:id { user: { role, site_ids: [], team_id, manager_id } } (name and email stay)
        def update
          user = authorize_portal find_user
          render_user ClientUsers::Save.call(client: current_client, user:, actor: current_client_user,
                                             params: params.expect(user: [ :role, :team_id, :manager_id, { site_ids: [] } ]))
        end

        # DELETE /portal/users/:id (Remove from Portal)
        def destroy
          ClientUsers::Remove.call(user: authorize_portal(find_user), actor: current_client_user)
          head :no_content
        end

        private

        def find_user = policy_scope([ :portal, ClientUser ]).find(params[:id])

        def render_user(user, status: :ok)
          viewer = ClientUser.includes(:user_sites).find(current_client_user.id)
          render_data ClientUser.includes(*INCLUDES).find(user.id), PortalUserBlueprint, status:, viewer:
        end
      end
    end
  end
end

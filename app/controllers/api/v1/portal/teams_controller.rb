# Client Portal › Settings › Users › Teams: name and manager (Their Manager approval step). Removing a team takes it off
# its people (and, from Phase 3, off approval rules).
module Api
  module V1
    module Portal
      class TeamsController < AppController
        # GET /portal/teams
        def index
          authorize_portal ClientTeam
          teams = policy_scope([ :portal, ClientTeam ]).includes(:manager, :users).order(Arel.sql("lower(name)"))
          render_data teams, PortalTeamBlueprint
        end

        # POST /portal/teams { team: { name, manager_id } }
        def create
          authorize_portal ClientTeam
          team = current_client.teams.create!(company_id: current_client.company_id, **team_params)
          render_data team, PortalTeamBlueprint, status: :created
        end

        # PATCH /portal/teams/:id { team: { name, manager_id } }
        def update
          team = authorize_portal find_team
          team.update!(team_params)
          render_data team, PortalTeamBlueprint
        end

        def destroy
          authorize_portal(find_team).destroy!
          head :no_content
        end

        private

        def find_team = policy_scope([ :portal, ClientTeam ]).find(params[:id])

        def team_params
          p = params.expect(team: %i[name manager_id])
          p[:manager_id] = p[:manager_id].presence if p.key?(:manager_id)
          p.to_h.symbolize_keys
        end
      end
    end
  end
end

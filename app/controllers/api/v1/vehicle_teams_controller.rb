# Vehicle teams (Manage Teams): renaming keeps its vehicles; deleting a team leaves its vehicles without one.
module Api
  module V1
    class VehicleTeamsController < BaseController
      def index
        authorize VehicleTeam
        render_list policy_scope(VehicleTeam).order(:name), VehicleTeamBlueprint
      end

      def create
        team = authorize VehicleTeam.new(team_params)
        team.save!
        render_data team, VehicleTeamBlueprint, status: :created
      end

      def update
        team = authorize VehicleTeam.find(params[:id])
        team.update!(team_params)
        render_data team, VehicleTeamBlueprint
      end

      # PUT /vehicle_teams/bulk { teams: [{ id?, name, color }] } — the whole Manage Teams window at once.
      def bulk
        authorize VehicleTeam, :update?
        rows = params.permit(teams: %i[id name color]).fetch(:teams, [])
        render_list VehicleTeams::Save.call(rows:), VehicleTeamBlueprint
      end

      def destroy
        authorize(VehicleTeam.find(params[:id])).destroy!
        head :no_content
      end

      private

      def team_params = params.expect(vehicle_team: %i[name color])
    end
  end
end

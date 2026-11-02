# Manage Teams saved at once: rows [{ id?, name, color }]. A row with an id renames / recolours that team (its vehicles
# move with it), a row without one adds a team, and a team left out is deleted (its vehicles are left with no team).
module VehicleTeams
  class Save < ApplicationService
    def initialize(rows:)
      @rows = Array(rows).map { |r| r.to_h.symbolize_keys.merge(name: r[:name].to_s.strip) }
    end

    def call
      raise Error, "Give every team a name" if @rows.any? { |r| r[:name].blank? }
      raise Error, "Two teams have the same name" if @rows.map { |r| r[:name].downcase }.uniq.size < @rows.size

      VehicleTeam.transaction do
        teams = VehicleTeam.all.index_by(&:id)
        keep = @rows.filter_map { |r| r[:id].presence&.to_i }
        raise ActiveRecord::RecordNotFound, "Team not found" if (keep - teams.keys).any?

        teams.except(*keep).each_value(&:destroy!)
        # Free the names first so two teams can swap names without hitting the unique index.
        teams.slice(*keep).each_value { |t| t.update_columns(name: "__#{t.id}") }
        @rows.map do |r|
          team = r[:id].present? ? teams.fetch(r[:id].to_i) : VehicleTeam.new
          team.update!(name: r[:name], color: r[:color].presence || team.color)
          team
        end
      end
    end
  end
end

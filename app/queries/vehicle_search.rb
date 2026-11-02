# The Scheduler's vehicle filters and sort, shared by the Vehicles list and the Scheduler grid:
# ownership[] (own managed external), size[] (sedan mpv small medium large), tags[], vip, team_id (id or "none"), q, sort.
class VehicleSearch
  SORTS = { "type" => :by_type, "smallest" => :smallest_first, "largest" => :largest_first }.freeze
  INCLUDES = [ :operator, :vehicle_team, :operator_driver, :current_log_card, :current_insurance_policy, { driver_schedules: :driver } ].freeze

  def initialize(scope, params)
    @scope = scope
    @params = params
  end

  def call
    s = @scope.includes(*INCLUDES).of_ownership(@params[:ownership]).of_size(@params[:size]).tagged(@params[:tags]).search(@params[:q])
    s = s.vip if ActiveModel::Type::Boolean.new.cast(@params[:vip])
    s = s.in_team(@params[:team_id])
    s.public_send(SORTS.fetch(@params[:sort].to_s, :by_type))
  end

  # Counts for the filter chips, over the whole kept fleet.
  def facets
    base = @scope
    {
      ownership: Vehicle::OWNERSHIPS.index_with { |k| base.of_ownership(k).count },
      size: Vehicle::SIZES.keys.index_with { |k| base.of_size(k).count },
      vip: base.vip.count,
      tags: base.pluck(:tags).flatten.reject { |t| t.casecmp?("vip") }.tally.sort.to_h,
      teams:
    }
  end

  # Team chips of the Vehicles pages: every team with its vehicles among the ownership picked
  # (teams with no vehicle there still show), then "No Team".
  def teams
    base = @scope.of_ownership(@params[:ownership])
    counts = base.group(:vehicle_team_id).count
    list = VehicleTeam.order(:name).map { |t| { id: t.id, name: t.name, color: t.color, count: counts[t.id].to_i } }
    { all: counts.values.sum, list:, none: counts[nil].to_i }
  end
end

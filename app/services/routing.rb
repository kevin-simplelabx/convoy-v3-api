# School Bus Route Plans: the routing engine runs in the routing service (routing-service/, Node); Rails builds its
# input from the database, keeps every run, and turns results into plans.
module Routing
  SESSION_KEYS = { "am" => "AM", "pm" => "PM", "asa" => "ASA" }.freeze

  module_function

  # The engine's default parameters (cached from the routing service); none when it cannot be reached.
  def defaults
    Client.current.meta["defaults"] || {}
  rescue Client::Unavailable
    {}
  end

  # The engine's bus types (cached from the routing service); none when it cannot be reached.
  def types
    Client.current.meta["types"] || []
  rescue Client::Unavailable
    []
  end

  # { rid => name } of a school's riders (the latest row of a rid that is in several lists).
  def rider_names(school, rids)
    return {} if rids.blank?

    SchoolRider.where(school_id: school.id, rid: rids).order(:id).pluck(:rid, :name).to_h
  end

  # Riders as the engine and Convoy OS list them: [{ rid, name }] in the given order.
  def rider_list(school, rids)
    names = rider_names(school, rids)
    Array(rids).map { { rid: it, name: names[it] } }
  end
end

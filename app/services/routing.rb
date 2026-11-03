# School Bus Route Plans: the routing engine runs in the routing service (routing-service/, Node); Rails builds its
# input from the database, keeps every run, and turns results into plans.
module Routing
  SESSION_KEYS = { "am" => "AM", "pm" => "PM", "asa" => "ASA" }.freeze
end

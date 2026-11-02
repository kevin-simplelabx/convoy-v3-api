# Singapore Unique Entity Number (business, local company, other entity) as written on ACRA records.
module Uen
  FORMAT = /\A(\d{8}[A-Z]|\d{9}[A-Z]|[TSR]\d{2}[A-Z]{2}\d{4}[A-Z])\z/
  HINT = "Examples: 53012345A, 201912345K, T09LL1234A".freeze
  MESSAGE = "looks wrong. #{HINT}".freeze

  def self.normalize(value) = value.to_s.strip.upcase.presence
end

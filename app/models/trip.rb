class Trip < ApplicationRecord
  self.primary_key = "id"

  belongs_to :company

  # camelCase keys from the frontend that map to proper DB columns
  SCALAR_FRONT_KEYS = %w[
    id sid kind title customer date start end pickup dropoff
    pax buses vid price rateHr days until endMode occ flight
    notes by sample no noFrom nN nR pair ret skipPH
  ].freeze

  def self.from_params(raw, company)
    vid = raw["vid"].presence
    {
      id:          raw["id"].presence || "t#{SecureRandom.hex(4)}",
      company_id:  company.id,
      school_id:   raw["sid"].presence&.to_i,
      vehicle_id:  vid ? vid.to_s.gsub(/\D/, '').presence&.to_i : nil,
      kind:        raw["kind"],
      title:       raw["title"],
      customer:    raw["customer"],
      trip_date:   raw["date"].presence,
      start_time:  raw["start"],
      end_time:    raw["end"],
      pickup:      raw["pickup"],
      dropoff:     raw["dropoff"],
      pax:         raw["pax"].to_i,
      buses:       [ 1, raw["buses"].to_i ].max,
      price:       raw["price"].to_f,
      rate_hr:     !!raw["rateHr"],
      days:        Array(raw["days"]).map(&:to_i),
      until_date:  raw["until"].presence,
      end_mode:    raw["endMode"].presence || "never",
      occ_count:   raw["occ"].presence&.to_i,
      flight:      raw["flight"],
      notes:       raw["notes"],
      by_user:     raw["by"],
      sample:      !!raw["sample"],
      no:          raw["no"]&.to_i,
      no_from:     raw["noFrom"].presence,
      n_n:         raw["nN"]&.to_i || 1,
      n_r:         !!raw["nR"],
      pair_id:     raw["pair"].presence,
      is_return:   !!raw["ret"],
      skip_ph:     raw.key?("skipPH") ? !!raw["skipPH"] : true,
      extra:       raw.except(*SCALAR_FRONT_KEYS),
    }
  end

  def to_api
    {
      "id"       => id,
      "kind"     => kind.to_s,
      "title"    => title.to_s,
      "customer" => customer.to_s,
      "date"     => trip_date&.iso8601.to_s,
      "start"    => start_time.to_s,
      "end"      => end_time.to_s,
      "pickup"   => pickup.to_s,
      "dropoff"  => dropoff.to_s,
      "pax"      => pax || 0,
      "buses"    => buses || 1,
      "vid"      => vehicle_id&.to_s || "",
      "price"    => price&.to_f || 0,
      "rateHr"   => !!rate_hr,
      "days"     => days || [],
      "until"    => until_date&.iso8601 || "",
      "endMode"  => end_mode || "never",
      "occ"      => occ_count || "",
      "flight"   => flight.to_s,
      "notes"    => notes.to_s,
      "by"       => by_user.to_s,
      "sample"   => !!sample,
      "no"       => no,
      "noFrom"   => no_from&.iso8601,
      "nN"       => n_n || 1,
      "nR"       => !!n_r,
      "pair"     => pair_id,
      "ret"      => !!is_return,
      "skipPH"   => skip_ph != false,
      "sid"      => school_id&.to_s || "",
    }.merge(extra || {})
  end
end

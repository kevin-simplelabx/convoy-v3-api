# A rate card. Default view: a row of the Rate Cards list. :full is the view / edit page, in the same shape the
# create / update body takes (so Duplicate = load it, rename, POST).
class RateCardBlueprint < ApplicationBlueprint
  fields :name, :description, :default_card, :archived_at, :lock_version
  field(:archived) { |c| c.archived? }
  field(:vehicle_types) { |c| c.vehicle_types.map { |t| { id: t.id, name: t.name, seats: t.seats } } }
  field(:periods_count) { |c| c.periods.size }
  # Clients priced by the card (the default card counts the clients with no card), from options[:client_counts].
  field(:clients_count) { |c, o| o[:client_counts]&.fetch(c.id, 0) }

  view :full do
    fields :wait_free_minutes, :wait_fee, :wait_block_minutes, :meet_and_greet, :meet_and_greet_fee, :distance_pricing,
           :stop_fees, :disposal_mode, :disposal_free_km
    field(:vehicle_type_ids) { |c| c.vehicle_types.map(&:id) }
    field(:periods) do |c|
      c.periods.map do |p|
        { id: p.id, name: p.name, days: p.days, override: p.override,
          ranges: p.ranges.sort_by(&:starts_at).map { |r| { starts_at: r.starts_at_hm, ends_at: r.ends_at_hm } },
          rates: p.rates.map { |r| { vehicle_type_id: r.vehicle_type_id, trip_rate: r.trip_rate, hourly_rate: r.hourly_rate } } }
      end
    end
    field(:distance_bands) do |c|
      c.distance_bands.map do |b|
        { up_to_km: b.up_to_km, per_km: b.per_km, amounts: amounts(c, "distance_band", b.id) }
      end
    end
    field(:stop_fee_amounts) { |c| amounts(c, "stop_fee") }
    field(:disposal_km_amounts) { |c| amounts(c, "disposal_km") }
    field(:clients) { |c| c.clients_using.order(:name).map { |cl| { id: cl.id, name: cl.name } } }
    field(:warnings) { |c| RateCards::Check.call(c) }
  end

  def self.amounts(card, kind, band_id = nil)
    card.amounts.select { |a| a.kind == kind && a.rate_card_distance_band_id == band_id }
        .map { |a| { vehicle_type_id: a.vehicle_type_id, amount: a.amount } }
  end
end

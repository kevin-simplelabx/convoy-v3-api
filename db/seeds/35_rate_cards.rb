# Rate cards from the Rate Cards starting card (RateCards::Standard): Standard Rates (default, distance, stop and
# Meet and Greet charges on), Corporate Contract Rates for Google and DBS, and an archived 2025 card.
with_company("SD") do
  build = lambda do |name, description, base, extra = {}|
    RateCard.find_by(name:) || RateCards::Save.call(card: RateCard.new,
                                                    params: RateCards::Standard.params(name:, description:, base:).merge(extra))
  end

  charges = { distance_pricing: true, stop_fees: true, meet_and_greet: true, meet_and_greet_fee: 25 }
  standard = build.("Standard Rates", "Default pricing for client bookings", 55, charges)
  RateCards::ChangeState.call(card: standard, action: :make_default) unless standard.default_card?
  contract = build.("Corporate Contract Rates", "Agreed rates for corporate accounts", 48, charges.merge(disposal_mode: "hourly_distance", disposal_free_km: 30))
  Client.kept.where(name: [ "Google Asia Pacific", "DBS Bank" ], rate_card_id: nil).update_all(rate_card_id: contract.id)
  old = build.("2025 Rates", "Last year's card, kept for reference", 50)
  RateCards::ChangeState.call(card: old, action: :archive) unless old.archived?
end

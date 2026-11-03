# School Bus money set-up sample for St. Stephen's School: AY 2026 Bus Fares (parents pay, distance tiers, per term,
# 1-way at 60%, Small Bus +10%, CCA per trip) locked, a fuel surcharge from next month, Payment & Refund Policy
# version 1, Payment Methods (company account, card +3%), Operator Pay (10 paid months, June / December earned by terms)
# with prices per bus size.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  year = school.academic_years.find_by!(key: "2026")

  unless year.fare_table
    FareTables::Save.call(year, {
      payer: "parents", basis: "distance", trip: "both", cycle: "period", distribution: "equal", one_way: { type: "pct", value: 60 },
      tiers: [ { max_km: 3, fare: 1680 }, { max_km: 6, fare: 1920 }, { max_km: 10, fare: 2160 }, { fare: 2400 } ],
      small: { on: true, type: "pct", value: 10, seats: 15 }, express: { on: false },
      cca: { on: true, per: "trip", price: "fixed", fixed: 8, split: "equal", riders: {} }
    }, user: admin)
  end
  unless school.fare_adjustments.exists?
    school.fare_adjustments.create!(academic_year: year, name: "Fuel Surcharge", kind: "pct", value: 5, from_month: Date.current.next_month.beginning_of_month,
                                    note: "Fuel surcharge (diesel above S$3.20 a litre)", created_by: admin)
  end
  unless school.policy_versions.exists?
    Policies::Publish.call(school, Policies.default.merge(effective_on: Date.current), user: admin)
  end
  unless school.payment_method
    school.create_payment_method!(bank_on: true, paynow_on: true, card_on: true, card_fee_kind: "pct", card_fee: 3, updated_by: admin)
  end
  unless school.operator_pay
    OperatorPays::Save.call(school, {
      scheme: "some", paid_months: [ 1, 2, 3, 4, 5, 7, 8, 9, 10, 11 ], part_basis: "school", break_months: [ 6, 12 ], break_pay: "earned", earn_by: "terms",
      rates: [
        { bus_type: "LARGE_45", fixed_on: true, monthly: 5200, ba_operator: 900, ba_us: 750 },
        { bus_type: "LARGE_40", fixed_on: true, monthly: 4800, ba_operator: 900, ba_us: 750 },
        { bus_type: "MEDIUM_23", fixed_on: true, monthly: 3600, rider_on: true, base_price: 3000, riders_included: 15, per_rider: 60, default_mode: "fixed" },
        { bus_type: "SMALL_13", fixed_on: true, monthly: 2400 }
      ]
    }, user: admin)
  end
end

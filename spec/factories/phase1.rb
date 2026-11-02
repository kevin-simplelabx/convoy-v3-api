FactoryBot.define do
  factory :public_holiday do
    company { ActsAsTenant.current_tenant || association(:company) }
    sequence(:date) { |n| Date.new(2026, 1, 1) + n }
    name { "Holiday" }
  end

  factory :calendar do
    company { ActsAsTenant.current_tenant || association(:company) }
    sequence(:name) { |n| "Calendar #{n}" }
    kind { :general }
  end

  factory :calendar_day do
    calendar
    company { calendar.company }
    kind { calendar.school? ? :hol : :off }
    starts_on { Date.new(2026, 12, 24) }
  end

  factory :client do
    company { ActsAsTenant.current_tenant || association(:company) }
    sequence(:name) { |n| "Client #{n}" }
  end

  factory :operator do
    company { ActsAsTenant.current_tenant || association(:company) }
    sequence(:name) { |n| "Operator #{n}" }
    kind { :managed }
    paynow_uen { "201912345K" }
    trait(:external) { kind { :external } }
  end

  factory :vehicle_team do
    company { ActsAsTenant.current_tenant || association(:company) }
    sequence(:name) { |n| "Team #{n}" }
  end

  factory :vehicle do
    company { ActsAsTenant.current_tenant || association(:company) }
    sequence(:plate) { |n| "PD#{1000 + n}A" }
    seats { 13 }
  end

  factory :driver do
    company { ActsAsTenant.current_tenant || association(:company) }
    name { Faker::Name.name }
    sequence(:phone) { |n| "+659#{format('%07d', n)}" }
    status { :active }
  end

  factory :operator_driver do
    company { ActsAsTenant.current_tenant || association(:company) }
    operator
    name { Faker::Name.name }
    sequence(:phone) { |n| "+658#{format('%07d', n)}" }
    status { :active }
  end

  factory :vehicle_type do
    sequence(:key) { |n| "type#{n}" }
    name { "Minibus" }
    seats { 13 }
  end
end

FactoryBot.define do
  factory :trip do
    company { ActsAsTenant.current_tenant || association(:company) }
    client { association(:client, company:) }
    kind { :ad_hoc }
    starts_on { Date.new(2026, 11, 2) }
    start_time { "08:00" }
    end_time { "09:00" }
    after(:build) do |trip|
      trip.stops.build(position: 0, name: "Changi Airport T3", use: "pu") if trip.stops.empty?
      trip.stops.build(position: 1, name: "Marina Bay Sands", use: "do") if trip.stops.size < 2 && !trip.disposal?
      trip.vehicle_requirements.build(vehicle_type: VehicleType.first || create(:vehicle_type), count: 1) if trip.vehicle_requirements.empty?
    end

    trait :weekdays do
      days { [ 1, 2, 3, 4, 5 ] }
      end_mode { :never }
    end
  end
end

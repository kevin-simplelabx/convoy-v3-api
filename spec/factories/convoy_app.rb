FactoryBot.define do
  factory :app_account do
    first_name { "Rachel" }
    last_name { "Tan" }
    terms_accepted_at { Time.current }

    trait(:unfinished) { first_name { nil }; last_name { nil }; terms_accepted_at { nil } }

    # Mobile / email identities in one go: create(:app_account, mobile: "+6591882045", email: "rachel@gmail.com").
    transient do
      mobile { nil }
      email { nil }
    end
    after(:create) do |account, e|
      create(:app_identity, app_account: account, kind: "mobile", value: e.mobile) if e.mobile
      create(:app_identity, :email, app_account: account, value: e.email) if e.email
    end
  end

  factory :app_identity do
    app_account
    kind { "mobile" }
    tag { "personal" }
    sequence(:value) { |n| "+659#{format('%07d', n)}" }
    verified_at { Time.current }

    trait(:email) { kind { "email" }; sequence(:value) { |n| "person#{n}@gmail.com" } }
    trait(:work) { kind { "email" }; tag { "work" }; sequence(:value) { |n| "person#{n}@google.com" } }
  end
end

# A Client Portal person of a client (the Convoy App finds them by email for a booking link).
FactoryBot.define do
  factory :client_user do
    client
    company_id { client.company_id }
    sequence(:name) { |n| "Client User #{n}" }
    sequence(:email) { |n| "user#{n}@client.test" }
    role { "member" }
    portal_account { PortalAccount.for_email!(email, name:) }
  end
end

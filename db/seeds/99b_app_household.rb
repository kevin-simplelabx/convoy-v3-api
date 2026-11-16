# Convoy App Household: the Tan Family of the HTML personas (Rachel Tan is the Admin and Billing Contact, David Tan is the
# Father and already in; two children at St. Stephen's School) from 99a_app_accounts.rb. Tan Mei Ling (Grandparent) has an
# account and an invite waiting to Accept, to try Home's invite card; the Quick Invite link is live. Idempotent.
rachel = AppIdentity.find_by!(kind: "mobile", value: ConvoyApp.normalize("mobile", "+65 9188 2045")).app_account
david = AppIdentity.find_by!(kind: "mobile", value: ConvoyApp.normalize("mobile", "+65 9177 3301")).app_account

mei_ling_mobile = ConvoyApp.normalize("mobile", "+65 9650 1187")
mei_ling = AppIdentity.find_by(kind: "mobile", value: mei_ling_mobile)&.app_account || AppAccount.new
mei_ling.update!(first_name: "Mei Ling", last_name: "Tan", name_order: "last", terms_accepted_at: mei_ling.terms_accepted_at || 30.days.ago)
mei_ling.identities.find_or_create_by!(kind: "mobile", value: mei_ling_mobile) { it.assign_attributes(tag: "personal", verified_at: 30.days.ago) }

household = rachel.household || Household.create!(name: "Tan Family", postal: "460412", block: "412", street: "Bedok North Ave 2", floor: "08", unit: "123",
                                                  created_by: rachel, billing_same: true, lat: 1.3236, lng: 103.9300)
household.members.find_or_create_by!(app_account: rachel) do |m|
  m.assign_attributes(status: :active, admin: true, billing_contact: true, relationship: "Mother", invited_via: :creator, joined_at: 20.days.ago,
                      invite_phone: ConvoyApp.normalize("mobile", "+65 9188 2045"))
end
household.members.find_or_create_by!(app_account: david) do |m|
  m.assign_attributes(status: :active, relationship: "Father", invited_via: :manual, invited_by: rachel, joined_at: 19.days.ago,
                      invite_phone: ConvoyApp.normalize("mobile", "+65 9177 3301"))
end
household.members.find_or_create_by!(app_account: mei_ling) do |m|
  m.assign_attributes(status: :invited, relationship: "Grandparent", invited_via: :manual, invited_by: rachel, invite_phone: mei_ling_mobile)
end

school = ActsAsTenant.without_tenant { School.find_by(name: "St. Stephen's School") }
[ [ "Ethan Tan", Date.new(2016, 3, 14), "Primary 4", "boy", "S4-0412" ], [ "Lucas Tan", Date.new(2021, 8, 2), "Primary 1", "boy", nil ] ].each do |name, dob, level, gender, sid|
  child = household.dependants.find_or_initialize_by(name:)
  child.update!(birth_date: dob, level:, gender:, student_id: sid, school_id: school&.id, school_name: "St. Stephen's School") if child.new_record?
end
household.invite_links.live.exists? || household.invite_links.create!(created_by: rachel)
puts "Convoy App Household: #{household.name} (#{household.members.active.count} adults, #{household.dependants.count} children)"

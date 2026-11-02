# Managed Clients record page: St. Stephen's School is a client (the school pays for its buses), linked to its
# School Bus school and the MOE calendar.
with_company("SD") do
  school = School.find_by!(name: "St. Stephen's School")
  sss = Client.find_or_initialize_by(name: "St. Stephen's School")
  sss.update!(kind: :company, uen: "T08GB0047K", contact_name: "Mrs Lee (Admin Office)", phone: "+65 6241 1243",
              email: "transport@ststephens.edu.sg", billing_address: "20 Siglap View, Singapore 455789")
  school.update!(client: sss) if school.client_id.nil?
end

# Google: Pasir Panjang billed as its own entity with two people on its invoices; bookable vehicles; who added the points.
with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  google = Client.find_by!(name: "Google Asia Pacific")
  pp = google.sites.find_by!(name: "Google Asia Pacific (Pasir Panjang)")
  pp.update!(own_billing: true, billing_name: "Google Asia Pacific Pte. Ltd. (PP)", billing_uen: "200817984R",
             billing_address: "3 Pasir Panjang Road, Singapore 117438", created_by: pp.created_by || owner)
  [ [ "Accounts Payable", "ap-sg@google.com", "to", false ], [ "Priya Raman", "priya.raman@google.com", "cc", true ] ]
    .each_with_index do |(name, email, send_as, attention), i|
      pp.billing_contacts.find_or_initialize_by(email:).update!(company_id: pp.company_id, name:, send_as:, attention:, position: i)
    end
  google.sites.where(created_by_id: nil).update_all(created_by_id: owner.id) # rubocop:disable Rails/SkipsModelValidations
  google.pickup_points.where(created_by_id: nil).update_all(created_by_id: owner.id) # rubocop:disable Rails/SkipsModelValidations
  VehicleType.enabled_for(google.company).where("seats >= 13").order(:seats).limit(3).each do |type|
    google.bookable_vehicle_types.find_or_create_by!(vehicle_type: type)
  end
end

# Client Users (Client Portal): Google with a Super Admin, a Finance Admin and a Site Admin for Mapletree; one person
# (priya.raman@google.com) is also a user of St. Stephen's School, to show the account picker at sign-in.
# Portal passwords: Portal123! (set), except the Site Admin, who has not signed in yet (first sign-in uses a code).
with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  google = Client.find_by!(name: "Google Asia Pacific")
  mbc = google.sites.find_by!(name: "Mapletree Business City")
  sss = Client.find_by!(name: "St. Stephen's School")
  [
    [ google, "Priya Raman", "Transport Lead", "priya.raman@google.com", "super", [], true ],
    [ google, "Kenneth Ong", "Finance", "kenneth.ong@google.com", "fin", [], true ],
    [ google, "Mei Ling", "Facilities, MBC", "meiling@google.com", "sa", [ mbc ], false ],
    [ sss, "Priya Raman", "Parent Volunteer", "priya.raman@google.com", "member", [], true ]
  ].each do |client, name, title, email, role, sites, password|
    account = PortalAccount.for_email!(email, name:)
    if password && !account.password_set?
      account.update!(password: "Portal123!", password_set_at: Time.current) if account.respond_to?(:password=)
    end
    user = client.users.kept.find_or_initialize_by(email:)
    user.update!(company_id: client.company_id, name:, title:, role:, portal_account: account, created_by: owner)
    sites.each { |s| user.user_sites.find_or_create_by!(client_site: s) }
  end
end

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
  pp = google.sites.find_by!(name: "Google Asia Pacific (Pasir Panjang)")
  sss = Client.find_by!(name: "St. Stephen's School")
  [
    [ google, "Priya Raman", "Transport Lead", "priya.raman@google.com", "super", [], true ],
    [ google, "Kenneth Ong", "Finance", "kenneth.ong@google.com", "fin", [], true ],
    [ google, "Mei Ling", "Facilities, MBC", "meiling@google.com", "sa", [ mbc ], false ],
    [ sss, "Priya Raman", "Parent Volunteer", "priya.raman@google.com", "member", [], true ],
    # Client Portal (every role): an Admin, a Site Super Admin for both sites, Site Finance for Pasir Panjang, two Members.
    [ google, "Linh Tran", "Office Manager", "linh.tran@google.com", "adm", [], true ],
    [ google, "Daniel Koh", "Real Estate & Workplace", "daniel.koh@google.com", "ssa", [ mbc, pp ], true ],
    [ google, "Aisha Rahman", "Finance, Pasir Panjang", "aisha.rahman@google.com", "sfin", [ pp ], true ],
    [ google, "Marcus Lim", "Events", "marcus.lim@google.com", "member", [ mbc ], true ],
    [ google, "Sarah Ng", "People Team", "sarah.ng@google.com", "member", [ pp ], true ]
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

# Client Portal › Settings: Google's teams (with managers, for the Their Manager approval step), each person's team and
# own manager, the legal name on invoices, and the logo and colour on the portal strip.
with_company("SD") do
  google = Client.find_by!(name: "Google Asia Pacific")
  user = ->(email) { google.users.kept.find_by!(email:) }
  { "Workplace" => "daniel.koh@google.com", "Events & People" => "linh.tran@google.com" }.each do |name, manager|
    google.teams.find_or_initialize_by(name:).update!(company_id: google.company_id, manager: user.(manager))
  end
  teams = google.teams.index_by(&:name)
  { "meiling@google.com" => [ "Workplace", nil ], "marcus.lim@google.com" => [ "Events & People", nil ],
    "sarah.ng@google.com" => [ "Events & People", "priya.raman@google.com" ] }.each do |email, (team, manager)|
    user.(email).update!(team: teams.fetch(team), manager: manager && user.(manager))
  end
  google.update!(billing_name: "Google Asia Pacific Pte. Ltd.", brand_color: "#4285F4")
  google.update!(brand_logo: SeedFiles.open("brand", "google-logo.png")) if google.brand_logo.blank?
end

# Client Portal › Approval Flows: Google's organisation flow (large bookings → Finance then Admins; Events & People booking
# at short notice → their manager; everything else → Site Admins) and Pasir Panjang's own flow (airport transfers →
# Aisha Rahman; otherwise their manager). Made once; changes in the portal are kept.
with_company("SD") do
  google = Client.find_by!(name: "Google Asia Pacific")
  pp = google.sites.find_by!(name: "Google Asia Pacific (Pasir Panjang)")
  user = ->(email) { google.users.kept.find_by!(email:) }
  org = ClientApprovalFlow.for!(google, nil)
  if org.ordered_rules.empty?
    Portal::SaveApprovalRule.call(flow: org, params: { name: "Large bookings", when: { over: 2000 }, same_person: "other",
                                                       steps: [ { who: [ "fin" ] }, { who: [ "admins" ] } ] })
    Portal::SaveApprovalRule.call(flow: org, params: { name: "Events at short notice", when: { team_ids: [ google.teams.find_by!(name: "Events & People").id ], lead_days: 3 },
                                                       steps: [ { who: [ "mgr" ] } ] })
    Portal::SaveApprovalRule.call(flow: org, rule: org.otherwise, params: { steps: [ { who: [ "site" ] } ] })
  end
  own = ClientApprovalFlow.for!(google, pp)
  if own.ordered_rules.empty?
    Portal::SaveApprovalRule.call(flow: own, params: { name: "Airport transfers", when: { kinds: [ "airport" ] },
                                                       steps: [ { who: [ "people" ], people_ids: [ user.("aisha.rahman@google.com").id ] } ] })
    Portal::SaveApprovalRule.call(flow: own, rule: own.otherwise, params: { steps: [ { who: [ "mgr" ] } ] })
  end
end

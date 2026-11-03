# Convoy Driver app accounts (sign in with the mobile and code 123456). Any seeded driver's mobile also works: the first
# sign-in creates the account. Eric Pang works for SimpleDrive, has an invitation from Island Coaches and drove for
# Comfort Charter Services before (Employment History); his profile is complete and verified with Singpass (email
# eric.pang@gmail.com / Driver123!). Tony Tan drives for Hup Seng (managed) on SimpleDrive's trips; his profile is half
# done (Complete My Profile). SimpleDrive's operations contacts and Company Links are what the app shows.
others = {
  "CCS" => "Comfort Charter Services",
  "ICS" => "Island Coaches"
}.to_h { |code, name| [ code, Company.find_or_create_by!(code:) { |c| c.name = name } ] }

eric_phone = "+6592104100"
with_company("CCS") do
  Driver.find_or_initialize_by(phone: eric_phone).tap do |d|
    d.update!(name: "Eric Pang", status: :past, invited_at: Time.zone.local(2022, 12, 20), responded_at: Time.zone.local(2024, 9, 30),
              joined_at: Time.zone.local(2023, 1, 10), left_at: Time.zone.local(2024, 9, 30))
  end
end
with_company("ICS") do
  company = others["ICS"]
  Driver.find_or_initialize_by(phone: eric_phone).tap do |d|
    d.update!(name: "Eric Pang", status: :pending, invited_at: 2.days.ago.change(hour: 10)) if d.new_record?
    d.record_invite!(kind: :invite, user: nil, message: Drivers::InviteMessage.for(d, company)) unless d.invites.exists?
  end
end

Company.find_by!(code: "SD").tap do |sd|
  sd.update!(ops_phone: "+6562221100", ops_hours: "Mon–Sat 05:30–20:00", ops_whatsapp: "+6592221100", ops_email: "ops@simpledrive.sg",
             depot_address: "12 Tuas Avenue 8, Singapore 639226 (office at the wash bay)")
  with_company("SD") do
    [ [ "Depot map", "https://simpledrive.sg/depot", "Bays and the wash bay" ], [ "Leave application form", "https://forms.gle/simpledrive-leave", "Google Form" ],
      [ "Incident report form", "https://forms.gle/simpledrive-incident", "Google Form" ] ].each_with_index do |(title, url, note), i|
      sd.links.find_or_create_by!(title:) { |l| l.assign_attributes(url:, note:, position: i) }
    end
  end
end

profiles = {
  eric_phone => {
    name: "Eric Pang", date_of_birth: Date.new(1979, 6, 21), nationality: "Singaporean", residential_status: "Singapore Citizen",
    id_number: "S7912345D", address: "Blk 120 Jurong West St 52 #03-150", postal_code: "640120", photo: "drv-2.png",
    email: "eric.pang@gmail.com", singpass: %w[name id_number date_of_birth nationality residential_status address postal_code],
    licences: [ { kind: "dl", classes: "Class 3, 4", number: "S7912345D", issued_on: Date.new(2004, 3, 2), expires_on: Date.new(2039, 6, 21) },
                { kind: "vl", classes: "BDVL", number: "BD107919", expires_on: Date.current + 60 } ]
  },
  "+6595807810" => {
    name: "Tony Tan", date_of_birth: Date.new(1985, 2, 9), nationality: "Malaysian", residential_status: "Permanent Resident",
    licences: [ { kind: "dl", classes: "Class 3", expires_on: Date.current + 20 } ]
  }
}
profiles.each do |phone, p|
  account = DriverAccount.for_phone!(phone)
  account.assign_attributes(p.slice(:name, :date_of_birth, :nationality, :residential_status, :id_number, :address, :postal_code, :email))
  account.phone_verified_at ||= 1.month.ago
  account.photo = SeedFiles.open("fleet", p[:photo]) if p[:photo] && account.photo.blank?
  if p[:email] && !account.password_set?
    account.assign_attributes(password: "Driver123!", password_confirmation: "Driver123!", password_set_at: 2.weeks.ago)
  end
  account.assign_attributes(singpass_verified_at: account.singpass_verified_at || 1.month.ago, singpass_fields: p[:singpass]) if p[:singpass]
  account.save!
  p[:licences].each { |l| account.licences.find_or_initialize_by(kind: l[:kind]).update!(l) }
  account.link_memberships!
  DriverApp::ShareProfile.call(account: account.reload)
end

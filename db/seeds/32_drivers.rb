# Drivers and Operator Drivers pages: every tab has someone (pending, declined, past), invites on record, what active
# drivers shared from the Convoy Driver app (KYC; the app writes it later) and one customer-facing display name.
with_company("SD") do
  admin = User.find_by(email: "ops@simpledrive.sg")
  company = ActsAsTenant.current_tenant
  hup_seng = Operator.find_by!(name: "Hup Seng Coaches")

  # A past own driver (left last month, last drove PD2185B) and a pending operator driver.
  Driver.find_or_initialize_by(phone: "+6590077889").tap do |d|
    d.update!(name: "Goh Chee Keong", status: :past, responded_at: 1.month.ago, joined_at: 2.years.ago, left_at: 1.month.ago, last_vehicle: Vehicle.kept.find_by(plate: "PD2185B"))
  end
  OperatorDriver.find_or_initialize_by(phone: "+6590088990").tap do |d|
    d.update!(name: "Rajesh Kumar", operator: hup_seng, status: :pending, notes: "Tamil, Malay. Knows Jurong well")
  end

  # Invites on record for drivers waiting to answer.
  (Driver.kept.pending + OperatorDriver.kept.pending).each do |d|
    next if d.invites.exists?

    d.record_invite!(kind: :invite, user: admin, message: Drivers::InviteMessage.for(d, company))
  end

  # What active drivers shared (fixed sample values per driver, so a second seed run changes nothing).
  nat = [ [ "Singapore Citizen", "Singaporean", "S" ], [ "Permanent Resident", "Malaysian", "S" ], [ "Work Permit", "Malaysian", "G" ] ]
  areas = [ "Jurong West St 52", "Woodlands Ave 6", "Bedok North Rd", "Tampines St 81", "Ang Mo Kio Ave 3", "Yishun Ring Rd" ]
  (Driver.kept.active.order(:id) + OperatorDriver.kept.active.order(:id)).each_with_index do |d, i|
    next if d.kyc_profile

    res, nationality, prefix = nat[i % nat.size]
    dob = Date.new(1968 + ((i * 7) % 28), 1 + (i % 12), 1 + ((i * 5) % 27))
    d.create_kyc_profile!(
      company:, email: "#{d.name.downcase.gsub(/[^a-z]+/, '.')}@gmail.com",
      address: "Blk #{120 + (i * 41)} #{areas[i % areas.size]}, ##{format('%02d', 3 + i)}-#{150 + (i * 13)}, Singapore #{640_000 + (i * 1_731)}",
      date_of_birth: dob, nationality:, residential_status: res,
      id_number: "#{prefix}#{format('%07d', 1_234_567 + (i * 98_765))}#{'ABCDEFGHIZJ'[i % 11]}",
      licence_class: i.even? ? "Class 4" : "Class 5", licence_qualified_on: dob + 25.years,
      vocational_licence_number: "BD#{100_000 + (i * 7_919)}",
      # one licence already expired, one ending soon, the rest valid for a while
      vocational_licence_expires_on: Date.current + [ -10, 45, 400, 700 ][i % 4].days,
      shared_at: d.responded_at || 3.months.ago
    )
  end

  # Shown to Your Customers: the company's photo-in-uniform name for Eric Pang.
  eric = Driver.kept.find_by(name: "Eric Pang")
  eric.update!(display_name: "Eric", display_set_by: admin, display_set_at: 2.weeks.ago) if eric && eric.display_set_at.nil?
end

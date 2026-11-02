# External Vehicles > Share Form: SimpleDrive's live link and two hired drivers' answers waiting for Review and Add.
with_company("SD") do
  admin = User.find_by(email: "ops@simpledrive.sg")
  link = ExternalVehicleShareLink.current!(user: admin)
  [
    { plate: "PB4417R", seats: 45, driver_name: "Mohd Hafiz", driver_phone: "+65 9345 1122", company_name: "Kallang Bus Charter",
      company_phone: "+65 9123 4567", paynow: "201912345K", created_at: 1.day.ago },
    { plate: "PC2208M", seats: 23, driver_name: "Lee Chong Wei", driver_phone: "+65 8765 4433", company_name: "Ang Mo Kio Coaches",
      company_phone: "+65 6455 7788", created_at: 3.hours.ago }
  ].each do |row|
    link.submissions.find_or_create_by!(plate: row[:plate]) { |s| s.assign_attributes(row.merge(company: ActsAsTenant.current_tenant)) }
  end
end

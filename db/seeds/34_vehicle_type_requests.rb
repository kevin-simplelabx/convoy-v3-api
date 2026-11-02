# Vehicle Types > Your Requests: one waiting for Convoy and one declined, so both the company list and Convoy Admin's
# Requests From Companies show something.
company = Company.find_by!(code: "SD")
admin = User.find_by(email: "ops@simpledrive.sg")
convoy = User.find_by(email: "admin@convoy.sg")
[
  { name: "Luxury Coach", seats: 27, reason: "Corporate client wants leather seats for roadshows", status: "pending" },
  { name: "Double Decker", seats: 80, reason: "Event shuttles", status: "declined", decided_by: convoy, decided_at: 5.days.ago }
].each do |row|
  VehicleTypeRequest.find_or_create_by!(company:, name: row[:name], seats: row[:seats]) do |r|
    r.assign_attributes(row.merge(requested_by: admin))
  end
end

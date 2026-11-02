# Settings > Users: SimpleDrive staff on the role presets, one limited to a school, one suspended, one deleted
# (its email is free again). Password for all: Simple123!
company = Company.find_by!(code: "SD")
owner = User.find_by!(email: "ops@simpledrive.sg")
preset = ->(id) { User::ROLE_PRESETS.find { |r| r[:id] == id }[:permissions] }

with_company("SD") do
  school = School.find_by(name: "St. Stephen's School")
  [
    { email: "planner@simpledrive.sg", name: "Priya Nair", permissions: preset["planner"], schools: [ school ].compact },
    { email: "opsmgr@simpledrive.sg", name: "Daniel Koh", permissions: preset["opsmgr"] },
    { email: "viewer@simpledrive.sg", name: "Aisha Rahman", permissions: [], status: :suspended },
    { email: "left@simpledrive.sg", name: "Kelvin Ong", permissions: preset["fleet"], deleted: true }
  ].each do |attrs|
    user = User.find_or_initialize_by(email: attrs[:email])
    user.assign_attributes(name: attrs[:name], company:, role: :member, permissions: attrs[:permissions],
                           status: attrs[:status] || :active, created_by: owner, all_schools: attrs[:schools].nil?)
    user.password = "Simple123!" if user.new_record?
    user.save!
    Array(attrs[:schools]).each { |s| user.user_schools.find_or_create_by!(school: s) }
    user.discard if attrs[:deleted] && user.kept?
  end
end

# Profile: a display name and mobile for the dispatcher.
User.find_by!(email: "dispatch@simpledrive.sg").update!(display_name: "Rachel (Dispatch)", mobile: "+65 9123 4567")

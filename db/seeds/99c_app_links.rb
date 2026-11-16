# Convoy App Organisations (Phase 3): the work emails of the seeded app accounts meet the clients.
#   rachel.tan@google.com -> Google Asia Pacific (clients.email_domains "google.com", seeded in 20_clients): staff shuttle invitation
#   priya_nair@moe.edu.sg -> a client user of St. Stephen's School (the teacher, Member): booking invitation
# Both stay "invited" so Accept / Not Me can be tried; Links::Match is the same service the app runs after a work email is verified.
with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  school = Client.kept.find_by!(name: "St. Stephen's School")
  email = "priya_nair@moe.edu.sg"
  account = PortalAccount.for_email!(email, name: "Priya Nair")
  user = school.users.kept.find_or_initialize_by(email:)
  user.update!(company_id: school.company_id, name: "Priya Nair", title: "Teacher", role: "member", portal_account: account, created_by: owner)
end

AppIdentity.where(tag: "work").includes(:app_account).map(&:app_account).uniq.each { ConvoyApp::Links::Match.call(account: it) }

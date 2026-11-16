# Convoy App accounts (sign in with the mobile or email and code 123456). Platform-wide, not per company; every identity
# is verified and the profile is complete (name, terms accepted). Personas follow the HTML ("Who Is Signed In"):
#   Rachel Tan     +65 9188 2045 + rachel.tan@gmail.com        parent (David is her husband in the Tan Family)
#   David Tan      +65 9177 3301                               parent
#   Rachel Tan     rachel.tan@google.com (work email only)     Google staff shuttle rider (HTML "staff"); signs in by email
#   Priya Nair     +65 9166 7720 + priya_nair@moe.edu.sg       St. Stephen's School teacher (HTML "school-staff"; the HTML
#                                                              gives her Rachel's mobile, but a mobile belongs to one account)
# Dates follow today: work emails were verified a few months ago, so they are not yet due for re-verification.
accounts = [
  { first_name: "Rachel", last_name: "Tan", identities: [ [ "mobile", "personal", "+65 9188 2045" ], [ "email", "personal", "rachel.tan@gmail.com" ] ] },
  { first_name: "David", last_name: "Tan", identities: [ [ "mobile", "personal", "+65 9177 3301" ] ] },
  { first_name: "Rachel", last_name: "Tan", identities: [ [ "email", "work", "rachel.tan@google.com" ] ] },
  { first_name: "Priya", last_name: "Nair", identities: [ [ "mobile", "personal", "+65 9166 7720" ], [ "email", "work", "priya_nair@moe.edu.sg" ] ] }
]

accounts.each do |attrs|
  rows = attrs[:identities].map { |kind, tag, value| [ kind, tag, ConvoyApp.normalize(kind, value) ] }
  account = AppIdentity.find_by(kind: rows.first[0], value: rows.first[2])&.app_account || AppAccount.new
  account.assign_attributes(first_name: attrs[:first_name], last_name: attrs[:last_name], terms_accepted_at: account.terms_accepted_at || 30.days.ago)
  account.save!
  rows.each_with_index do |(kind, tag, value), i|
    account.identities.find_or_create_by!(kind:, value:) { |identity| identity.assign_attributes(tag:, verified_at: tag == "work" ? (90 + i).days.ago : 30.days.ago) }
  end
end

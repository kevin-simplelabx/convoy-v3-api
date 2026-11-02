# Company Settings: SimpleDrive's country confirmed by its owner, and one declined Request a Country Change in the history.
# Only Singapore is open, so the old request (to Malaysia) is written without the "country is open" check.
company = Company.find_by!(code: "SD")
owner = User.find_by!(email: "ops@simpledrive.sg")
convoy = User.find_by!(email: "admin@convoy.sg")

company.update!(country_set_by: owner) if company.country_set_by_id.nil?

unless company.country_requests.exists?
  company.country_requests.new(from_country: "SG", to_country: "MY", reason: "Looking at running a Johor Bahru cross-border service",
                               status: :declined, requested_by: owner, decided_by: convoy, decided_at: Time.zone.local(2026, 10, 20, 10))
         .save!(validate: false)
end

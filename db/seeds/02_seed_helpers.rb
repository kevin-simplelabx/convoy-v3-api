# Helpers for the seed files below (loaded first by name order).
module SeedFiles
  def self.open(*path) = File.open(Rails.root.join("db/seeds/files", *path))
end

def with_company(code, &)
  ActsAsTenant.with_tenant(Company.find_by!(code:), &)
end

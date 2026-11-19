# Helpers for the seed files below (loaded first by name order).
module SeedFiles
  def self.open(*path) = File.open(Rails.root.join("db/seeds/files", *path))

  # The platform's preset vehicle types (01_vehicle_types). Seeds pick from these only: a type someone added on a shared
  # server (staging) has no rate card in the seed, so booking or paying with it fails.
  def self.vehicle_types(company) = VehicleType.enabled_for(company).where(key: PRESET_TYPE_KEYS)

  PRESET_TYPE_KEYS = YAML.load_file(Rails.root.join("config/presets/vehicle_types.yml")).pluck("key").freeze
end

def with_company(code, &)
  ActsAsTenant.with_tenant(Company.find_by!(code:), &)
end

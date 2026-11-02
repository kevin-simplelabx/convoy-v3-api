# Every trip's runs up to the horizon (trips saved through Trips::Save already have them; this fills older data).
Company.find_each do |company|
  ActsAsTenant.with_tenant(company) do
    Time.use_zone(company.timezone) { Occurrences::Sync.call(trips: Trip.kept.pluck(:id), routes: SchoolRoutes.running_ids) }
  end
end

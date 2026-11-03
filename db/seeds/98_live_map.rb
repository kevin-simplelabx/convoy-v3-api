# Live Map sample: a device for every SimpleDrive bus and "now" — buses on a run with GPS and stops so far, parked buses,
# two offline. Refresh it later with `bin/rails live_map:simulate` (LOOP=10 keeps it moving).
with_company("SD") do
  Time.use_zone(ActsAsTenant.current_tenant.timezone) { Telematics::Simulate.call }
end

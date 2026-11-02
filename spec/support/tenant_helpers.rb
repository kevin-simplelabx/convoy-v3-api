# Model specs: `within_tenant` runs each example inside a company.
module TenantHelpers
  def within_tenant(company = nil, &)
    ActsAsTenant.with_tenant(company || create(:company), &)
  end
end

RSpec.configure do |config|
  config.include TenantHelpers
  # A before hook (not around) so the company is created inside the example's transaction.
  config.before(:each, :tenant) { ActsAsTenant.current_tenant = create(:company) }
end

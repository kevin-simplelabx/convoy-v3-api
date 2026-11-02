# Every company-owned model is scoped to ActsAsTenant.current_tenant (the signed-in user's company).
# A query on a tenant model without a tenant raises, so data can never leak between companies.
ActsAsTenant.configure do |config|
  config.require_tenant = true
end

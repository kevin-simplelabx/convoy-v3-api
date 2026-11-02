# Company-owned records: scoped to the current company (acts_as_tenant). Each model declares its own `audited`
# (trip parts are audited with their trip, for Changes to This Trip).
module TenantScoped
  extend ActiveSupport::Concern

  included do
    # optional: the id is checked instead of loading the company for every record (nested rows saved together)
    acts_as_tenant :company, optional: true
    validates :company_id, presence: true
  end
end

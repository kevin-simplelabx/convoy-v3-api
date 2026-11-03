# The company's Route Plans parameters (Parameters panel): engine parameter overrides (times, dwell, penalties, route
# rules, bus types, headroom, stability, effort, priority preset) on top of the engine defaults (routing service /meta).
# A document read and written whole, so jsonb; each routing run keeps a copy.
# == Schema Information
#
# Table name: routing_settings
# Database name: primary
#
#  id            :bigint           not null, primary key
#  params        :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  updated_by_id :bigint
#
# Indexes
#
#  index_routing_settings_on_company_id  (company_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class RoutingSetting < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :updated_by, class_name: "User", optional: true
end

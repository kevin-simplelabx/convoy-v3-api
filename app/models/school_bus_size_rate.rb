# The default monthly price an operator is paid for a route by bus size at a school: Fixed Monthly and / or Fixed + Per
# Rider (base price for up to riders_included, then per rider), which one a new route takes (default_mode), and the bus
# attendant add-on when the operator provides one (ba_operator) or we do (ba_us).
# == Schema Information
#
# Table name: school_bus_size_rates
# Database name: primary
#
#  id              :bigint           not null, primary key
#  ba_operator     :decimal(12, 2)
#  ba_us           :decimal(12, 2)
#  base_price      :decimal(12, 2)
#  bus_type        :string           not null
#  default_mode    :string           default("fixed"), not null
#  fixed_on        :boolean          default(TRUE), not null
#  monthly         :decimal(12, 2)
#  per_rider       :decimal(12, 2)
#  rider_on        :boolean          default(FALSE), not null
#  riders_included :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  school_id       :bigint           not null
#
# Indexes
#
#  index_school_bus_size_rates_on_school_id_and_bus_type  (school_id,bus_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#
class SchoolBusSizeRate < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school

  validates :bus_type, inclusion: { in: SchoolBus::BUS_TYPES.keys }, uniqueness: { scope: :school_id }
  validates :default_mode, inclusion: { in: %w[fixed rider] }

  def label = SchoolBus::BUS_TYPES.dig(bus_type, :label)
end

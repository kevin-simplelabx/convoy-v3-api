# == Schema Information
#
# Table name: maintenance_lines
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  brand                :string
#  description          :string
#  line_type            :string           default("part"), not null
#  model                :string
#  part_number          :string
#  position             :integer          default(0), not null
#  quantity             :decimal(10, 2)   default(1.0), not null
#  tyre_position        :string
#  unit_price           :decimal(12, 2)   default(0.0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_id           :bigint           not null
#  maintenance_visit_id :bigint           not null
#
# Indexes
#
#  index_maintenance_lines_on_company_id            (company_id)
#  index_maintenance_lines_on_maintenance_visit_id  (maintenance_visit_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (maintenance_visit_id => maintenance_visits.id)
#
# A line of a workshop invoice: a part, a tyre (with its position), labour or other; price before GST.
class MaintenanceLine < ApplicationRecord
  include TenantScoped
  audited associated_with: :visit

  belongs_to :visit, class_name: "MaintenanceVisit", foreign_key: :maintenance_visit_id, inverse_of: :lines

  enum :line_type, { part: "part", tyre: "tyre", labour: "labour", other: "other" }, validate: true

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  def amount = (quantity.to_d * unit_price.to_d).round(2)
end

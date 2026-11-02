# HR > Salary Simulator > Templates: one of five shared slots holding a made-up month for testing pay schemes.
# == Schema Information
#
# Table name: pay_simulator_templates
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  attendance_percent   :integer
#  description          :text
#  jobs                 :jsonb            not null
#  month                :date             not null
#  name                 :string           not null
#  on_time_percent      :integer
#  rejected             :integer          default(0), not null
#  routes               :jsonb            not null
#  school_holidays_from :date
#  school_holidays_to   :date
#  slot                 :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_id           :bigint           not null
#  pay_scheme_id        :bigint
#  saved_by_id          :bigint
#  vehicle_type_id      :bigint
#
# Indexes
#
#  index_pay_simulator_templates_on_company_id_and_slot  (company_id,slot) UNIQUE
#  index_pay_simulator_templates_on_pay_scheme_id        (pay_scheme_id)
#  index_pay_simulator_templates_on_saved_by_id          (saved_by_id)
#  index_pay_simulator_templates_on_vehicle_type_id      (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (pay_scheme_id => pay_schemes.id)
#  fk_rails_...  (saved_by_id => users.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
class PaySimulatorTemplate < ApplicationRecord
  include TenantScoped

  SLOTS = (1..5)

  belongs_to :pay_scheme, optional: true
  belongs_to :vehicle_type, optional: true
  belongs_to :saved_by, class_name: "User", optional: true

  normalizes :name, with: ->(v) { v.to_s.squish.presence }

  validates :slot, inclusion: { in: SLOTS }, uniqueness: { scope: :company_id }
  validates :name, presence: true
  validates :month, presence: true
end

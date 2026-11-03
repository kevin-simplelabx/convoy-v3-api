# One line on the Driver app's bell for a driver at a company: a trip given to them (run_assigned), moved or put on
# another bus (run_changed), given to another driver (run_unassigned), cancelled (run_cancelled), no longer planned
# (run_removed), a bus to take over (vehicle_switch), or a notice from the office (notice). Unread until opened; an
# Acknowledge notice until acknowledged. pushed_at: when it went out as a push (not sent yet).
# == Schema Information
#
# Table name: driver_notifications
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  body               :string
#  kind               :string           not null
#  occurrence_date    :date
#  pushed_at          :datetime
#  read_at            :datetime
#  title              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  driver_id          :bigint
#  driver_notice_id   :bigint
#  occurrence_id      :bigint
#  operator_driver_id :bigint
#  vehicle_id         :bigint
#
# Indexes
#
#  idx_on_operator_driver_id_created_at_0144cf6d7d         (operator_driver_id,created_at) WHERE (operator_driver_id IS NOT NULL)
#  index_driver_notifications_on_driver_id_and_created_at  (driver_id,created_at) WHERE (driver_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (driver_id => drivers.id) ON DELETE => cascade
#  fk_rails_...  (driver_notice_id => driver_notices.id) ON DELETE => cascade
#  fk_rails_...  (operator_driver_id => operator_drivers.id) ON DELETE => cascade
#  fk_rails_...  (vehicle_id => vehicles.id) ON DELETE => nullify
#
class DriverNotification < ApplicationRecord
  include TenantScoped

  KINDS = %w[run_assigned run_changed run_unassigned run_cancelled run_removed vehicle_switch notice].freeze

  belongs_to :driver, optional: true
  belongs_to :operator_driver, optional: true
  belongs_to :vehicle, optional: true
  belongs_to :notice, class_name: "DriverNotice", foreign_key: :driver_notice_id, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :title, presence: true

  scope :for_member, ->(m) { where(m.is_a?(OperatorDriver) ? { operator_driver_id: m.id } : { driver_id: m.id }) }
  scope :unread, -> { where(read_at: nil) }

  # { driver_id: } or { operator_driver_id: } for a membership.
  def self.member_key(m) = m.is_a?(OperatorDriver) ? { operator_driver_id: m.id } : { driver_id: m.id }
end

# One driver a notice went to: when they opened it and, for an Acknowledge notice, when they acknowledged it.
# == Schema Information
#
# Table name: driver_notice_recipients
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  acknowledged_at    :datetime
#  read_at            :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  driver_id          :bigint
#  driver_notice_id   :bigint           not null
#  operator_driver_id :bigint
#
# Indexes
#
#  index_driver_notice_recipients_on_driver_id           (driver_id)
#  index_driver_notice_recipients_on_operator_driver_id  (operator_driver_id)
#  index_driver_notice_recipients_unique                 (driver_notice_id,driver_id,operator_driver_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (driver_id => drivers.id) ON DELETE => cascade
#  fk_rails_...  (driver_notice_id => driver_notices.id) ON DELETE => cascade
#  fk_rails_...  (operator_driver_id => operator_drivers.id) ON DELETE => cascade
#
class DriverNoticeRecipient < ApplicationRecord
  belongs_to :notice, class_name: "DriverNotice", foreign_key: :driver_notice_id, inverse_of: :recipients
  belongs_to :driver, optional: true
  belongs_to :operator_driver, optional: true

  def member = driver || operator_driver
end

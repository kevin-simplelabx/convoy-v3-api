# == Schema Information
#
# Table name: replacement_notifications
# Database name: primary
#
#  id             :bigint           not null, primary key
#  audiences      :string           default([]), not null, is an Array
#  channels       :string           default([]), not null, is an Array
#  message        :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  replacement_id :bigint           not null
#  sent_by_id     :bigint
#
# Indexes
#
#  index_replacement_notifications_on_company_id      (company_id)
#  index_replacement_notifications_on_replacement_id  (replacement_id)
#  index_replacement_notifications_on_sent_by_id      (sent_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (replacement_id => replacements.id)
#  fk_rails_...  (sent_by_id => users.id)
#
# A message about a replacement to guests and / or parents (recorded only for now).
class ReplacementNotification < ApplicationRecord
  include TenantScoped

  AUDIENCES = %w[guests parents].freeze
  CHANNELS = %w[email push].freeze # WhatsApp and Client Portal are not available yet

  belongs_to :replacement
  belongs_to :sent_by, class_name: "User", optional: true

  validates :message, presence: true
  validate { errors.add(:audiences, "pick who to notify") if audiences.empty? || (audiences - AUDIENCES).any? }
  validate { errors.add(:channels, "pick how to send the message") if channels.empty? || (channels - CHANNELS).any? }
  validate { errors.add(:channels, "Convoy App messages go to parents only") if channels.include?("push") && audiences.exclude?("parents") }
end

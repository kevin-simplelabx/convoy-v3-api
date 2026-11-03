# A parent reminder of a policy version: before / on / after the due date (days), sent by email, WhatsApp and / or the
# Convoy App with its texts ([Parent Name], [Child Name], [Amount], [Due Date], [Period], [School], [Pay Link],
# [Late Charge]). Sending comes with School Bus finance; this is the set-up.
# == Schema Information
#
# Table name: policy_reminders
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  app                      :boolean          default(FALSE), not null
#  app_body                 :string
#  app_title                :string
#  days                     :integer          default(0), not null
#  email                    :boolean          default(FALSE), not null
#  email_body               :text
#  email_subject            :string
#  position                 :integer          not null
#  timing                   :string           not null
#  whatsapp                 :boolean          default(FALSE), not null
#  whatsapp_body            :text
#  school_policy_version_id :bigint           not null
#
# Indexes
#
#  idx_on_school_policy_version_id_position_dcb28cb4b5  (school_policy_version_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (school_policy_version_id => school_policy_versions.id) ON DELETE => cascade
#
class PolicyReminder < ApplicationRecord
  belongs_to :school_policy_version, inverse_of: :reminders

  validates :timing, inclusion: { in: %w[before on after] }
end

# HR > Rewards: something drivers redeem points for in the driver app (only active ones are shown there).
# == Schema Information
#
# Table name: pay_rewards
# Database name: primary
#
#  id              :bigint           not null, primary key
#  description     :text
#  discarded_at    :datetime
#  photo           :string
#  points_required :integer          not null
#  status          :string           default("inactive"), not null
#  title           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#
# Indexes
#
#  index_pay_rewards_on_company_id_and_status  (company_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class PayReward < ApplicationRecord
  include TenantScoped
  include Discard::Model
  audited

  mount_uploader :photo, RewardPhotoUploader

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  normalizes :title, with: ->(v) { v.to_s.squish.presence }

  validates :title, presence: true
  validates :points_required, numericality: { only_integer: true, greater_than: 0 }
end

# The Quick Invite link of a Household ("convoy.sg/j/TAN-7KQ2"): works 7 days. Whoever opens it signs in and asks to join;
# the Admin approves (Asked to Join), nobody joins without approval.
# == Schema Information
#
# Table name: household_invite_links
# Database name: primary
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime         not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :bigint
#  household_id  :bigint           not null
#
# Indexes
#
#  index_household_invite_links_on_created_by_id  (created_by_id)
#  index_household_invite_links_on_household_id   (household_id)
#  index_household_invite_links_on_token          (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => app_accounts.id) ON DELETE => nullify
#  fk_rails_...  (household_id => households.id) ON DELETE => cascade
#
class HouseholdInviteLink < ApplicationRecord
  VALID_FOR = 7.days
  URL = "https://convoy.sg/j/%s".freeze

  belongs_to :household
  belongs_to :created_by, class_name: "AppAccount", optional: true

  scope :live, -> { where(expires_at: Time.current..) }

  before_validation :set_token, :set_expiry, on: :create

  def live? = expires_at > Time.current
  def url = format(URL, token)

  private

  def set_expiry = self.expires_at ||= VALID_FOR.from_now

  # "TAN-7KQ2": the first letters of the family name and 4 characters that are easy to read out (no 0 / O / 1 / I).
  def set_token
    return if token.present?

    prefix = household.name.to_s.upcase.gsub(/[^A-Z]/, "")[0, 3].presence || "FAM"
    loop do
      self.token = "#{prefix}-#{Array.new(4) { %w[2 3 4 5 6 7 8 9 A B C D E F G H J K L M N P Q R S T U V W X Y Z].sample }.join}"
      break unless self.class.exists?(token:)
    end
  end
end

# One adult of a Household: an account that is in the Family, was invited in the app (Manual Invite, only people who already
# have an account) or asked to join through the Quick Invite link. invite_phone = the number the invite was sent to; a row
# without an account is allowed by the table (invite by mobile) but no screen creates one yet. status: invited (waiting for them to Accept / Not Me), requested (Asked to Join, waiting for the Admin),
# active, declined. admin / billing_contact: the creator is Admin; the Billing Contact is chosen at Set Up Your Family.
# photo: the face the bus attendant checks before hand-over (not the profile photo).
# == Schema Information
#
# Table name: household_members
# Database name: primary
#
#  id              :bigint           not null, primary key
#  admin           :boolean          default(FALSE), not null
#  billing_contact :boolean          default(FALSE), not null
#  invite_name     :string
#  invite_phone    :string
#  invited_via     :string           not null
#  joined_at       :datetime
#  photo           :string
#  relationship    :string
#  status          :string           default("invited"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  app_account_id  :bigint
#  household_id    :bigint           not null
#  invited_by_id   :bigint
#
# Indexes
#
#  index_household_members_invited_phone           (invite_phone) WHERE ((status)::text = 'invited'::text)
#  index_household_members_on_app_account_id       (app_account_id)
#  index_household_members_on_household_id         (household_id)
#  index_household_members_on_invited_by_id        (invited_by_id)
#  index_household_members_one_admin               (household_id) UNIQUE WHERE admin
#  index_household_members_one_billing_contact     (household_id) UNIQUE WHERE billing_contact
#  index_household_members_one_family_per_account  (app_account_id) UNIQUE WHERE ((status)::text = 'active'::text)
#  index_household_members_one_invite_per_phone    (household_id,invite_phone) UNIQUE WHERE ((invite_phone IS NOT NULL) AND ((status)::text = 'invited'::text))
#  index_household_members_one_per_account         (household_id,app_account_id) UNIQUE WHERE ((app_account_id IS NOT NULL) AND ((status)::text = ANY ((ARRAY['invited'::character varying, 'requested'::character varying, 'active'::character varying])::text[])))
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#  fk_rails_...  (household_id => households.id) ON DELETE => cascade
#  fk_rails_...  (invited_by_id => app_accounts.id) ON DELETE => nullify
#
class HouseholdMember < ApplicationRecord
  RELATIONSHIPS = [ "Mother", "Father", "Grandparent", "Relative", "Domestic Helper", "Family Friend" ].freeze
  PARENTS = %w[Mother Father].freeze

  audited associated_with: :household

  belongs_to :household, inverse_of: :members
  belongs_to :app_account, optional: true
  belongs_to :invited_by, class_name: "AppAccount", optional: true
  has_many :dependant_guardians, dependent: :delete_all

  mount_uploader :photo, ImageUploader

  enum :status, { invited: "invited", requested: "requested", active: "active", declined: "declined" }, validate: true
  enum :invited_via, { creator: "creator", quick: "quick", manual: "manual" }, validate: true, prefix: :via

  normalizes :invite_phone, with: ->(v) { v.present? ? AppIdentity.normalize_mobile(v) : nil }
  normalizes :invite_name, with: ->(v) { v.to_s.squish.presence }

  validates :relationship, inclusion: { in: RELATIONSHIPS }, allow_nil: true
  validate :who_is_invited

  scope :pending, -> { where(status: %i[invited requested]) }
  scope :invitations_for, ->(account) { where(status: :invited, app_account_id: account.id) }

  def parent? = PARENTS.include?(relationship)

  # Name as the Household shows it: the account's display name, or the name typed when inviting by mobile.
  def name = app_account&.display_name || invite_name || phone_display

  def first_name = app_account&.first_name || name.to_s.split.first

  def phone = app_account&.mobile&.value || invite_phone

  def phone_display = phone && AppIdentity.new(kind: "mobile", value: phone).display

  private

  def who_is_invited
    errors.add(:base, "Choose who to invite") if app_account_id.blank? && invite_phone.blank?
  end
end

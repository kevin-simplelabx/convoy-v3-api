# A family in the Convoy App (platform-wide, not per company): its name, postal address and billing address, the adults
# (household_members), the children (dependants) and the Quick Invite links. The creator is the Admin. Delete Family
# discards it (the children stay discarded for the records companies must keep); members are removed.
# == Schema Information
#
# Table name: households
# Database name: primary
#
#  id              :bigint           not null, primary key
#  billing_address :text
#  billing_same    :boolean          default(TRUE), not null
#  block           :string           not null
#  discarded_at    :datetime
#  floor           :string
#  lat             :decimal(10, 7)
#  line2           :string
#  lng             :decimal(10, 7)
#  name            :string           not null
#  postal          :string           not null
#  street          :string           not null
#  unit            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  created_by_id   :bigint
#
# Indexes
#
#  index_households_on_created_by_id  (created_by_id)
#  index_households_on_discarded_at   (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => app_accounts.id) ON DELETE => nullify
#
class Household < ApplicationRecord
  include Discard::Model

  audited only: %i[name postal block street floor unit line2 billing_same billing_address discarded_at]

  belongs_to :created_by, class_name: "AppAccount", optional: true
  has_many :members, -> { order(:id) }, class_name: "HouseholdMember", dependent: :delete_all, inverse_of: :household
  has_many :dependants, -> { kept.order(:birth_date, :id) }, dependent: :delete_all, inverse_of: :household
  has_many :invite_links, class_name: "HouseholdInviteLink", dependent: :delete_all

  normalizes :name, :block, :street, :floor, :unit, :line2, :billing_address, with: ->(v) { v.to_s.squish.presence }
  normalizes :postal, with: ->(v) { v.to_s.gsub(/\D/, "").presence }

  validates :name, :block, :street, presence: true
  validates :postal, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }
  validates :billing_address, presence: true, unless: :billing_same?

  # "Blk 412 Bedok North Ave 2, #08-123, line 2": flats show the floor and unit, landed homes just the house number.
  def address
    flat = floor.present? && unit.present?
    line = [ flat ? "Blk #{block}" : block, street ].compact_blank.join(" ")
    [ line, (flat ? "##{floor}-#{unit}" : nil), line2 ].compact_blank.join(", ")
  end

  def admin = members.find(&:admin?)
  def active_members = members.select(&:active?)
end

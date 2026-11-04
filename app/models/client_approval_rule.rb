# A rule of an approval flow: when (sites, booked by people or teams, a trip type, estimate over, booked less than N days
# ahead; empty = every booking) and then (up to 5 steps; none = approved automatically). One Otherwise rule per flow
# takes every booking no other rule matches. same_person: when one person is on two steps, once = their approval covers the
# later step too, other = the later step needs someone else.
# == Schema Information
#
# Table name: client_approval_rules
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  booked_by_condition     :boolean          default(FALSE), not null
#  lead_days               :integer
#  name                    :string
#  otherwise               :boolean          default(FALSE), not null
#  over_amount             :decimal(12, 2)
#  position                :integer          default(0), not null
#  same_person             :string           default("once"), not null
#  sites_condition         :boolean          default(FALSE), not null
#  trip_kinds              :string           default([]), not null, is an Array
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  client_approval_flow_id :bigint           not null
#  company_id              :bigint           not null
#
# Indexes
#
#  idx_on_client_approval_flow_id_position_8a3d7c610a  (client_approval_flow_id,position)
#  index_client_approval_rules_one_otherwise           (client_approval_flow_id) UNIQUE WHERE otherwise
#
# Foreign Keys
#
#  fk_rails_...  (client_approval_flow_id => client_approval_flows.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#
class ClientApprovalRule < ApplicationRecord
  include TenantScoped
  audited associated_with: :flow

  MAX_STEPS = 5
  SAME_PERSON = %w[once other].freeze

  belongs_to :flow, class_name: "ClientApprovalFlow", foreign_key: :client_approval_flow_id, inverse_of: :rules
  has_many :rule_sites, class_name: "ClientApprovalRuleSite", dependent: :delete_all
  has_many :sites, through: :rule_sites, source: :client_site
  has_many :rule_bookers, class_name: "ClientApprovalRuleBooker", dependent: :delete_all
  has_many :bookers, through: :rule_bookers, source: :client_user
  has_many :rule_teams, class_name: "ClientApprovalRuleTeam", dependent: :delete_all
  has_many :teams, through: :rule_teams, source: :client_team
  has_many :steps, -> { order(:position, :id) }, class_name: "ClientApprovalStep", inverse_of: :rule, dependent: :destroy

  normalizes :name, with: ->(v) { v.to_s.squish.presence }

  validates :name, presence: { message: "is needed: name the rule, e.g. Large bookings" }, unless: :otherwise?
  validates :same_person, inclusion: { in: SAME_PERSON }
  validates :over_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :lead_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :known_trip_kinds

  # Does a booking { site_id, booker (client user), kinds [], amount, lead } meet every condition (logic/app-feed.js routeMatch).
  def match?(booking)
    return true if otherwise?
    return false if sites_condition && !site_ids_list.include?(booking[:site_id])
    return false if booked_by_condition && !booked_by?(booking[:booker])
    return false if trip_kinds.any? && !trip_kinds.intersect?(Array(booking[:kinds]))
    return false if over_amount && !(booking[:amount].to_d > over_amount)
    return false if lead_days && !(booking[:lead] && booking[:lead] < lead_days)

    true
  end

  def site_ids_list = rule_sites.map(&:client_site_id)

  private

  def booked_by?(booker)
    return false unless booker

    rule_bookers.any? { it.client_user_id == booker.id } || (booker.client_team_id && rule_teams.any? { it.client_team_id == booker.client_team_id })
  end

  def known_trip_kinds
    errors.add(:trip_kinds, "has a trip type that does not exist") unless (trip_kinds - BookingTrip.kinds.keys).empty?
  end
end

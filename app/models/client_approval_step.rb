# A step of an approval rule: who is asked (groups, all on the same level: Their Manager, Site Admins, Finance, Admins,
# named people) and whether any one of them or everyone must approve.
# == Schema Information
#
# Table name: client_approval_steps
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  need                    :string           default("any"), not null
#  position                :integer          default(0), not null
#  who                     :string           default([]), not null, is an Array
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  client_approval_rule_id :bigint           not null
#
# Indexes
#
#  idx_on_client_approval_rule_id_position_10238c12fc  (client_approval_rule_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (client_approval_rule_id => client_approval_rules.id) ON DELETE => cascade
#
class ClientApprovalStep < ApplicationRecord
  WHO = { "mgr" => "Their Manager", "site" => "Site Admins", "fin" => "Finance", "admins" => "Admins", "people" => "Named people" }.freeze
  NEEDS = %w[any all].freeze

  audited associated_with: :rule

  belongs_to :rule, class_name: "ClientApprovalRule", foreign_key: :client_approval_rule_id, inverse_of: :steps
  has_many :step_people, class_name: "ClientApprovalStepPerson", dependent: :delete_all
  has_many :people, through: :step_people, source: :client_user

  validates :need, inclusion: { in: NEEDS }
  validate :known_groups

  def person_ids = step_people.map(&:client_user_id)

  private

  def known_groups
    errors.add(:who, "needs at least one group") if who.empty?
    errors.add(:who, "has a group that does not exist") unless (who - WHO.keys).empty?
  end
end

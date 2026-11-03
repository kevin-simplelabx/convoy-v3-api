# A line Ops adds to an operator's pay run: a deduction (taxi claim, replacement we arranged, penalty, damage, other) or
# an addition (covered another route — with the matching deduction on the other operator —, extra trips, ERP / parking,
# other), its date, route, amount, reason and files.
# == Schema Information
#
# Table name: school_payout_adjustments
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  adj_on             :date             not null
#  amount             :decimal(12, 2)   not null
#  kind               :string           not null
#  reason             :text             not null
#  route_label        :string
#  sign               :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_id      :bigint
#  pair_id            :bigint
#  paired_operator_id :bigint
#  school_payout_id   :bigint           not null
#
# Indexes
#
#  index_school_payout_adjustments_on_school_payout_id  (school_payout_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (paired_operator_id => operators.id)
#  fk_rails_...  (school_payout_id => school_payouts.id) ON DELETE => cascade
#
class SchoolPayoutAdjustment < ApplicationRecord
  KINDS = { "Taxi claim" => -1, "Replacement bus we arranged" => -1, "Penalty / late arrival" => -1, "Damage" => -1, "Covered another route" => 1,
            "Extra trips" => 1, "ERP / parking claim" => 1, "Other addition" => 1, "Other deduction" => -1 }.freeze

  belongs_to :school_payout, inverse_of: :adjustments
  belongs_to :paired_operator, class_name: "Operator", optional: true
  belongs_to :pair, class_name: "SchoolPayoutAdjustment", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :files, class_name: "SchoolPayoutFile", dependent: :destroy, inverse_of: :school_payout_adjustment

  validates :kind, :reason, :adj_on, presence: true
  validates :sign, inclusion: { in: [ -1, 1 ] }
  validates :amount, numericality: { greater_than: 0 }
end

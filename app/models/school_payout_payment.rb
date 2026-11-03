# Money paid to the operator on a school pay run, recorded on the pay run (an Operator Payments batch records its own).
# == Schema Information
#
# Table name: school_payout_payments
# Database name: primary
#
#  id               :bigint           not null, primary key
#  amount           :decimal(12, 2)   not null
#  method           :string           not null
#  paid_on          :date             not null
#  reference        :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  recorded_by_id   :bigint
#  school_payout_id :bigint           not null
#
# Indexes
#
#  index_school_payout_payments_on_school_payout_id  (school_payout_id)
#
# Foreign Keys
#
#  fk_rails_...  (recorded_by_id => users.id)
#  fk_rails_...  (school_payout_id => school_payouts.id) ON DELETE => cascade
#
class SchoolPayoutPayment < ApplicationRecord
  METHODS = [ "Bank Transfer", "PayNow", "GIRO", "Cheque", "Cash" ].freeze

  belongs_to :school_payout, inverse_of: :payments
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :paid_on, :method, presence: true
  validates :amount, numericality: { greater_than: 0 }
end

# Money let off a School Bus bill: the late fee (Waive Late Fee in Collections) or part of the bill itself, with why.
# == Schema Information
#
# Table name: school_bill_waivers
# Database name: primary
#
#  id             :bigint           not null, primary key
#  amount         :decimal(12, 2)   not null
#  kind           :string           default("late"), not null
#  reason         :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  created_by_id  :bigint
#  school_bill_id :bigint           not null
#
# Indexes
#
#  index_school_bill_waivers_on_school_bill_id  (school_bill_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_bill_id => school_bills.id) ON DELETE => cascade
#
class SchoolBillWaiver < ApplicationRecord
  KINDS = %w[late other].freeze

  belongs_to :school_bill, inverse_of: :waivers
  belongs_to :created_by, class_name: "User", optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :amount, numericality: { greater_than: 0 }
  validates :reason, presence: true
end

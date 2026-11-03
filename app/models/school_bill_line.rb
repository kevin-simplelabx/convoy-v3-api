# A line of a School Bus bill: what it is for (and which child), and the amount (credit as a negative line).
# == Schema Information
#
# Table name: school_bill_lines
# Database name: primary
#
#  id             :bigint           not null, primary key
#  amount         :decimal(12, 2)   not null
#  child_name     :string
#  description    :string           not null
#  position       :integer          default(0), not null
#  school_bill_id :bigint           not null
#
# Indexes
#
#  index_school_bill_lines_on_school_bill_id  (school_bill_id)
#
# Foreign Keys
#
#  fk_rails_...  (school_bill_id => school_bills.id) ON DELETE => cascade
#
class SchoolBillLine < ApplicationRecord
  belongs_to :school_bill, inverse_of: :lines

  validates :description, presence: true
end

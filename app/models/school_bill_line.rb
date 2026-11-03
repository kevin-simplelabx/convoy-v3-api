# A line of a School Bus bill: what it is for (and which child, by rider id), the amount and a note on a part charge
# (joins or stops during the period); a credit note carried from an earlier bill is a negative line.
# == Schema Information
#
# Table name: school_bill_lines
# Database name: primary
#
#  id             :bigint           not null, primary key
#  amount         :decimal(12, 2)   not null
#  child_name     :string
#  description    :string           not null
#  note           :string
#  position       :integer          default(0), not null
#  rid            :string
#  credit_note_id :bigint
#  school_bill_id :bigint           not null
#
# Indexes
#
#  index_school_bill_lines_on_school_bill_id  (school_bill_id)
#
# Foreign Keys
#
#  fk_rails_...  (credit_note_id => school_documents.id) ON DELETE => nullify
#  fk_rails_...  (school_bill_id => school_bills.id) ON DELETE => cascade
#
class SchoolBillLine < ApplicationRecord
  belongs_to :school_bill, inverse_of: :lines
  belongs_to :credit_note, class_name: "SchoolDocument", optional: true

  validates :description, presence: true
end

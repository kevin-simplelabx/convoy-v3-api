# An instalment of a vehicle loan marked as paid.
# == Schema Information
#
# Table name: vehicle_loan_payments
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  instalment_no        :integer          not null
#  paid_on              :date             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  recorded_by_id       :bigint
#  vehicle_financial_id :bigint           not null
#
# Indexes
#
#  index_vehicle_loan_payments_on_recorded_by_id  (recorded_by_id)
#  index_vehicle_loan_payments_unique             (vehicle_financial_id,instalment_no) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (recorded_by_id => users.id)
#  fk_rails_...  (vehicle_financial_id => vehicle_financials.id)
#
class VehicleLoanPayment < ApplicationRecord
  audited associated_with: :vehicle_financial

  belongs_to :vehicle_financial
  belongs_to :recorded_by, class_name: "User", optional: true
end

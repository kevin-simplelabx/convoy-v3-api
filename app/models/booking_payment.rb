# Money of a prepaid booking (Personal, or Pay Myself from a school account), paid in the Convoy App: one payment when it is
# sent (the estimate plus the card fee), refunds when trips are cancelled or declined. Simulated (decision 2026-11-04):
# collected / refunded at once. These bookings are settled here, never on a Client Invoice (decision 2026-11-16).
# amount: booking money; card_fee: the method's surcharge beside it (refunded in proportion).
# == Schema Information
#
# Table name: booking_payments
# Database name: primary
#
#  id           :bigint           not null, primary key
#  amount       :decimal(12, 2)   not null
#  card_fee     :decimal(12, 2)   default(0.0), not null
#  kind         :string           not null
#  method       :string           not null
#  method_label :string           not null
#  note         :text
#  paid_at      :datetime         not null
#  reference    :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  booking_id   :bigint           not null
#  company_id   :bigint           not null
#
# Indexes
#
#  index_booking_payments_on_booking_id  (booking_id)
#  index_booking_payments_on_company_id  (company_id)
#  index_booking_payments_one_payment    (booking_id,kind) UNIQUE WHERE ((kind)::text = 'payment'::text)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (company_id => companies.id)
#
class BookingPayment < ApplicationRecord
  include TenantScoped
  audited associated_with: :booking

  belongs_to :booking

  enum :kind, { payment: "payment", refund: "refund" }, validate: true
  enum :method, { card: "card", paynow: "paynow" }, prefix: :by, validate: true

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :card_fee, numericality: { greater_than_or_equal_to: 0 }
  validates :reference, :method_label, :paid_at, presence: true

  def charged = amount + card_fee
end

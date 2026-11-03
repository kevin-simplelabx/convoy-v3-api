# How parents may pay a school's School Bus bills in the Convoy App: Bank Transfer, PayNow, Card — each on / off with an
# admin fee passed on (none, fixed S$, or % up to 10) — paid into the company account (Finance Settings › Payment
# Details) or the school's own account. Not saved = Bank Transfer and PayNow, no fee, company account.
# == Schema Information
#
# Table name: school_payment_methods
# Database name: primary
#
#  id              :bigint           not null, primary key
#  account_name    :string
#  account_number  :string
#  bank_fee        :decimal(12, 2)
#  bank_fee_kind   :string           default("none"), not null
#  bank_on         :boolean          default(TRUE), not null
#  card_fee        :decimal(12, 2)
#  card_fee_kind   :string           default("none"), not null
#  card_on         :boolean          default(FALSE), not null
#  own_account     :boolean          default(FALSE), not null
#  paynow_fee      :decimal(12, 2)
#  paynow_fee_kind :string           default("none"), not null
#  paynow_on       :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  bank_id         :bigint
#  company_id      :bigint           not null
#  paynow_id       :string
#  school_id       :bigint           not null
#  updated_by_id   :bigint
#
# Indexes
#
#  index_school_payment_methods_on_school_id  (school_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (bank_id => banks.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class SchoolPaymentMethod < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  METHODS = { "bank" => "Bank Transfer", "paynow" => "PayNow", "card" => "Card" }.freeze

  belongs_to :school
  belongs_to :bank, optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  validates :bank_fee_kind, :paynow_fee_kind, :card_fee_kind, inclusion: { in: %w[none fixed pct] }
end

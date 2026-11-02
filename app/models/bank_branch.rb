# A branch of a bank (ACH branch code). UOB-style banks look a branch up by the account's first 3 digits
# (account_prefix); other rows have none.
# == Schema Information
#
# Table name: bank_branches
# Database name: primary
#
#  id             :bigint           not null, primary key
#  account_prefix :string
#  code           :string           not null
#  name           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  bank_id        :bigint           not null
#
# Indexes
#
#  index_bank_branches_on_bank_id_and_account_prefix  (bank_id,account_prefix) UNIQUE WHERE (account_prefix IS NOT NULL)
#  index_bank_branches_on_bank_id_and_code            (bank_id,code)
#
# Foreign Keys
#
#  fk_rails_...  (bank_id => banks.id)
#
class BankBranch < ApplicationRecord
  belongs_to :bank

  validates :code, format: { with: /\A\d{3}\z/ }
  validates :name, presence: true
end

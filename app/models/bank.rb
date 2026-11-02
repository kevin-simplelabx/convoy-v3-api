# A Singapore bank (ACH bank code), platform-wide. branch_rule says how the branch code of an account is found:
# Banks::BranchFor.
# == Schema Information
#
# Table name: banks
# Database name: primary
#
#  id          :bigint           not null, primary key
#  branch_rule :string           not null
#  code        :string           not null
#  key         :string           not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  short_name  :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_banks_on_code  (code)
#  index_banks_on_key   (key) UNIQUE
#
class Bank < ApplicationRecord
  RULES = {
    "pre3" => "Branch code is the first 3 digits of the account number",
    "posb" => "All 9-digit POSB accounts use branch code 081",
    "pre3drop" => "Branch code is the first 3 digits. The account number is sent without them",
    "uob" => "Branch code is looked up from the first 3 digits of the account number",
    "sc" => "Branch code is 0 plus the first 2 digits of the account number",
    "list" => "Pick the branch where the account was opened"
  }.freeze

  has_many :branches, -> { order(:code) }, class_name: "BankBranch", dependent: :destroy

  validates :key, :code, :name, :short_name, presence: true
  validates :key, uniqueness: true
  validates :branch_rule, inclusion: { in: RULES.keys }

  def rule_text = RULES[branch_rule]

  # "DBS | DBS Bank Ltd (7171)" for pickers.
  def label = "#{short_name == name ? name : "#{short_name} | #{name}"} (#{code})"

  # Branches picked from a list (rule list); a bank with one branch needs no pick.
  def pick_branch? = branch_rule == "list" && branches.size > 1
end

# == Schema Information
#
# Table name: company_sequences
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  value      :bigint           default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_company_sequences_on_company_id           (company_id)
#  index_company_sequences_on_company_id_and_name  (company_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# Running numbers per company, taken under a row lock so two requests never get the same number.
class CompanySequence < ApplicationRecord
  include TenantScoped

  def self.next!(name) = next_block!(name, 1)

  # The number next_block! would give now, without reserving it (a preview: another save may take it first).
  def self.peek(name, start: 1) = [ (find_by(name: name.to_s)&.value || 0) + 1, start ].max

  # Reserve `count` numbers in a row and return the first. `start` is the first number a new sequence gives.
  def self.next_block!(name, count, start: 1)
    seq = create_or_find_by!(name: name.to_s)
    seq.with_lock do
      first = [ seq.value + 1, start ].max
      seq.update!(value: first + count - 1)
      first
    end
  end
end

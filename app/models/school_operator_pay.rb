# Operator Pay settings of a school (School Bus): paid months (all 12; chosen only; chosen in full and the others at
# part_pct), part months counted by school or calendar days, break months paid as a retainer — in full, or earned by the
# terms (or school days, with a grace start and deducted days) the route ran in the term(s) before. Prices per bus
# size are school_bus_size_rates.
# == Schema Information
#
# Table name: school_operator_pays
# Database name: primary
#
#  id               :bigint           not null, primary key
#  break_months     :integer          default([6, 12]), not null, is an Array
#  break_pay        :string           default("full"), not null
#  deduct_days      :integer          default(0), not null
#  earn_by          :string           default("terms"), not null
#  grace_start_days :integer          default(0), not null
#  paid_months      :integer          default([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]), not null, is an Array
#  part_basis       :string           default("school"), not null
#  part_pct         :decimal(5, 2)    default(50.0), not null
#  scheme           :string           default("all"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  company_id       :bigint           not null
#  school_id        :bigint           not null
#  updated_by_id    :bigint
#
# Indexes
#
#  index_school_operator_pays_on_school_id  (school_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (updated_by_id => users.id)
#
class SchoolOperatorPay < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school
  belongs_to :updated_by, class_name: "User", optional: true

  validates :scheme, inclusion: { in: %w[all some part] }
  validates :part_basis, inclusion: { in: %w[school cal] }
  validates :break_pay, inclusion: { in: %w[full earned] }
  validates :earn_by, inclusion: { in: %w[terms days] }
  validates :part_pct, numericality: { in: 0..100 }

  # Share of a month's price paid under the scheme (1, part_pct / 100 or 0) as a decimal.
  def rate(month)
    return 1.to_d if scheme == "all" || paid_months.include?(month)

    scheme == "part" ? part_pct.to_d / 100 : 0.to_d
  end
end

# The last time Convoy drafted a school's bills for one billing period of an academic year: when, by whom (none = the
# daily job), the due date and period label, and the notes on what was left out.
# == Schema Information
#
# Table name: school_bill_runs
# Database name: primary
#
#  id               :bigint           not null, primary key
#  auto             :boolean          default(FALSE), not null
#  drafted_at       :timestamptz      not null
#  due_on           :date
#  label            :string
#  period_index     :integer          not null
#  skipped          :string           default([]), not null, is an Array
#  unlinked         :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  academic_year_id :bigint           not null
#  company_id       :bigint           not null
#  drafted_by_id    :bigint
#  school_id        :bigint           not null
#
# Indexes
#
#  idx_on_school_id_academic_year_id_period_index_014fe39487  (school_id,academic_year_id,period_index) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (drafted_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#
class SchoolBillRun < ApplicationRecord
  include TenantScoped

  belongs_to :school
  belongs_to :academic_year
  belongs_to :drafted_by, class_name: "User", optional: true
end

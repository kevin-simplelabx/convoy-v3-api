# A Year Setup step saved and locked (Save & Lock): per academic year (calendar, sessions, …) or per school (levels,
# bus attendants, …). Locked steps cannot change until unlocked (Unlock to Edit).
# == Schema Information
#
# Table name: setup_locks
# Database name: primary
#
#  id               :bigint           not null, primary key
#  locked_at        :timestamptz      not null
#  section          :string           not null
#  academic_year_id :bigint
#  company_id       :bigint           not null
#  locked_by_id     :bigint
#  school_id        :bigint           not null
#
# Indexes
#
#  index_setup_locks_unique  (school_id, COALESCE(academic_year_id, (0)::bigint), section) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (locked_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#
class SetupLock < ApplicationRecord
  include TenantScoped

  YEAR_SECTIONS = %w[calendar sessions fares].freeze
  SCHOOL_SECTIONS = %w[levels attendants operator_pay].freeze
  SECTIONS = YEAR_SECTIONS + SCHOOL_SECTIONS

  belongs_to :school
  belongs_to :academic_year, optional: true
  belongs_to :locked_by, class_name: "User", optional: true

  validates :section, inclusion: { in: SECTIONS }
end

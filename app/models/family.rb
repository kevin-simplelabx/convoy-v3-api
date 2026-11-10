# A family of the School Bus service: guardians and the riders it has at the school (and others). Code FAM-0001 (unique
# in the school); name_mode auto = "<father's surname, else mother's, else the first guardian's> FAMILY" (upper case),
# custom = typed. source app = registered in the Convoy App (sample data until the app exists).
# == Schema Information
#
# Table name: families
# Database name: primary
#
#  id            :bigint           not null, primary key
#  address       :text
#  code          :string           not null
#  name          :string           not null
#  name_mode     :string           default("auto"), not null
#  postal        :string
#  registered_at :timestamptz
#  sample        :boolean          default(FALSE), not null
#  source        :string           default("console"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  school_id     :bigint           not null
#
# Indexes
#
#  index_families_on_school_id           (school_id)
#  index_families_on_school_id_and_code  (school_id,code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#
class Family < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :school
  has_many :guardians, -> { order(:position, :id) }, class_name: "FamilyGuardian", dependent: :delete_all, inverse_of: :family
  has_many :family_riders, dependent: :delete_all

  validates :code, presence: true, uniqueness: { scope: :school_id, case_sensitive: false }
  validates :name, presence: true
  validates :name_mode, inclusion: { in: %w[auto custom] }

  normalizes :code, with: ->(v) { v.to_s.strip.upcase }

  before_validation :auto_name, if: -> { name_mode == "auto" }

  # The next code at a school (per school, as the prototype's famNext).
  def self.next_code(school)
    n = where(school:).where("code ~ '^FAM-[0-9]+$'").pluck(Arel.sql("MAX(SUBSTRING(code FROM 5)::int)")).first.to_i
    "FAM-#{(n + 1).to_s.rjust(4, '0')}"
  end

  def auto_name
    g = guardians.find { it.relationship == "Father" } || guardians.find { it.relationship == "Mother" } || guardians.first
    surname = g&.last_name.presence || g&.first_name.presence
    self.name = surname ? "#{surname.upcase} Family" : (name.presence || "New Family")
  end
end

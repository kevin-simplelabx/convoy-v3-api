# A level a school offers (School Levels), in order; final levels graduate (registration thanks them instead of inviting
# a renewal). Riders' grade matches the name, ignoring case. section = the "What the School Offers" card it came from.
# == Schema Information
#
# Table name: school_levels
# Database name: primary
#
#  id         :bigint           not null, primary key
#  final      :boolean          default(FALSE), not null
#  name       :string           not null
#  position   :integer          not null
#  section    :string           default("custom"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  school_id  :bigint           not null
#
# Indexes
#
#  index_school_levels_unique_name  (school_id, lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#
class SchoolLevel < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  # key => [name, group, description, default levels], as in Convoy OS.
  SECTIONS = {
    "pre" => [ "Pre-school", nil, "Playgroup, Nursery 1 and 2, K1, K2", [ "Playgroup", "Nursery 1", "Nursery 2", "K1", "K2" ] ],
    "pri" => [ "Primary", nil, "P1 to P6", %w[P1 P2 P3 P4 P5 P6] ],
    "sec" => [ "Secondary", nil, "Sec 1 to Sec 4", [ "Sec 1", "Sec 2", "Sec 3", "Sec 4" ] ],
    "jc" => [ "Junior College", nil, "JC1 and JC2", %w[JC1 JC2] ],
    "grd" => [ "Grade", "International", "Pre-K, K, Grade 1 to 12", [ "Pre-K", "K" ] + (1..12).map { "Grade #{it}" } ],
    "yr" => [ "Year", "International", "Reception, Year 1 to 13", [ "Reception" ] + (1..13).map { "Year #{it}" } ]
  }.freeze

  belongs_to :school

  validates :name, presence: true
  validates :section, inclusion: { in: SECTIONS.keys + [ "custom" ] }
end

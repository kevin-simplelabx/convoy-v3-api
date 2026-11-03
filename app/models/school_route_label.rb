# How a school's routes are named in one session (Route Labels): prefix, first number, zero padding, suffix — "AM 01".
# == Schema Information
#
# Table name: school_route_labels
# Database name: primary
#
#  id         :bigint           not null, primary key
#  digits     :integer          default(0), not null
#  prefix     :string           default(""), not null
#  session    :string           not null
#  start      :integer          default(1), not null
#  suffix     :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  school_id  :bigint           not null
#
# Indexes
#
#  index_school_route_labels_on_school_id_and_session  (school_id,session) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#
class SchoolRouteLabel < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  SESSIONS = %w[am pm asa].freeze
  DEFAULTS = { "am" => { prefix: "AM " }, "pm" => { prefix: "PM " }, "asa" => { prefix: "CCA " } }.freeze

  belongs_to :school

  validates :session, inclusion: { in: SESSIONS }, uniqueness: { scope: :school_id }
  validates :start, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :digits, numericality: { only_integer: true, in: 0..4 }

  # Label of the n-th route (1-based).
  def label(n)
    num = start + n - 1
    "#{prefix}#{digits.positive? ? num.to_s.rjust(digits, '0') : num}#{suffix}"
  end
end

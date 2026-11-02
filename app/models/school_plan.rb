# == Schema Information
#
# Table name: school_plans
# Database name: primary
#
#  id             :bigint           not null, primary key
#  days           :integer          default([1, 2, 3, 4, 5]), not null, is an Array
#  effective_from :date             not null
#  effective_to   :date
#  in_use         :boolean          default(TRUE), not null
#  name           :string           not null
#  session        :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  school_id      :bigint           not null
#
# Indexes
#
#  index_school_plans_on_company_id  (company_id)
#  index_school_plans_on_school_id   (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#
# A route plan of a school for one session (AM, PM, CCA), in use between two dates on its weekdays.
class SchoolPlan < ApplicationRecord
  include TenantScoped
  audited

  SESSIONS = { "am" => "AM", "pm" => "PM", "asa" => "CCA" }.freeze

  belongs_to :school
  has_many :routes, -> { order(:number) }, class_name: "SchoolRoute", dependent: :destroy, inverse_of: :plan

  enum :session, SESSIONS.keys.index_by(&:itself), prefix: :session, validate: true

  validates :name, :effective_from, presence: true

  scope :running_between, lambda { |from, to|
    where(in_use: true).where(effective_from: ..to).where("effective_to IS NULL OR effective_to >= ?", from)
  }

  def session_name = SESSIONS[session]
  # Calendar shifts: morning routes move on Late Arrival, the others on Early Dismissal.
  def calendar_session = session_am? ? "am" : "pm"
end

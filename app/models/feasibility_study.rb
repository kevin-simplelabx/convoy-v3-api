# A Feasibility Study (company sandbox): the school (an existing one, or a prospect placed by its postal code), its
# students by postal code, how they would be picked up (door-to-door, or the nearest Stop Library PUDO within walk_m),
# bus prices per size with the attendant add-on, fare tiers, and scenarios planned by the routing engine.
# == Schema Information
#
# Table name: feasibility_studies
# Database name: primary
#
#  id              :bigint           not null, primary key
#  name            :string           not null
#  pickup          :string           default("door"), not null
#  prospect_lat    :decimal(10, 7)
#  prospect_lng    :decimal(10, 7)
#  prospect_name   :string
#  prospect_postal :string
#  school_mode     :string           default("prospect"), not null
#  walk_m          :integer          default(400), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  school_id       :bigint
#
# Indexes
#
#  index_feasibility_studies_on_company_id_and_updated_at  (company_id,updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#
class FeasibilityStudy < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :school, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :rows, -> { order(:id) }, class_name: "FeasibilityRow", dependent: :delete_all, inverse_of: :feasibility_study
  has_many :bus_prices, -> { order(:bus_type) }, class_name: "FeasibilityBusPrice", dependent: :delete_all, inverse_of: :feasibility_study
  has_many :fare_tiers, -> { order(:position) }, class_name: "FeasibilityFareTier", dependent: :delete_all, inverse_of: :feasibility_study
  has_many :scenarios, -> { order(:position) }, class_name: "FeasibilityScenario", dependent: :delete_all, inverse_of: :feasibility_study

  validates :name, presence: true
  validates :school_mode, inclusion: { in: %w[existing prospect] }
  validates :pickup, inclusion: { in: %w[door lib] }

  # Where the school is: { name, short, lat, lng } or nil.
  def place
    if school_mode == "existing"
      school&.lat ? { name: school.name, short: school.short, lat: school.lat.to_f, lng: school.lng.to_f } : nil
    elsif prospect_lat
      { name: prospect_name.presence || "Prospect school", short: prospect_name.presence || "Prospect", lat: prospect_lat.to_f, lng: prospect_lng.to_f }
    end
  end

  def students = rows.sum(&:riders)
end

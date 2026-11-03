# A bus session of a school's academic year (Bus Sessions): to school (arrival window) or to home (dismissal, departure,
# arrival window), or a CCA / ASA run home (only inside the calendar's CCA periods); door-to-door or point-to-point;
# the longest journey; its days (operating days only) and day variants with other times. Times are minutes after midnight.
# == Schema Information
#
# Table name: bus_sessions
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  arrive_from         :integer
#  arrive_to           :integer
#  cca                 :boolean          default(FALSE), not null
#  days                :integer          default([]), not null, is an Array
#  depart              :integer
#  direction           :string           not null
#  dismissal           :integer
#  max_journey_minutes :integer          default(60), not null
#  name                :string           not null
#  notes               :text
#  position            :integer          not null
#  service             :string           default("d2d"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  academic_year_id    :bigint           not null
#  company_id          :bigint           not null
#
# Indexes
#
#  index_bus_sessions_on_academic_year_id_and_position  (academic_year_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#
class BusSession < ApplicationRecord
  include TenantScoped
  include MinuteTime
  audited associated_with: :academic_year

  DIRECTIONS = %w[to_school to_home].freeze
  SERVICES = %w[d2d p2p].freeze

  belongs_to :academic_year
  has_many :variants, -> { order(:position) }, class_name: "BusSessionVariant", dependent: :delete_all, inverse_of: :bus_session

  minute_time :arrive_from, :arrive_to, :dismissal, :depart

  validates :name, presence: true
  validates :direction, inclusion: { in: DIRECTIONS }
  validates :service, inclusion: { in: SERVICES }
  validates :max_journey_minutes, numericality: { only_integer: true, greater_than: 0 }

  def to_home? = direction == "to_home"
end

# A special operating day (Holidays & Special Days): Early / Late Dismissal, Early / Late Arrival or Other, with the time
# and a description. Late Arrival moves the AM runs, Early Dismissal the PM and CCA runs (RouteGenerator).
# == Schema Information
#
# Table name: school_special_days
# Database name: primary
#
#  id               :bigint           not null, primary key
#  date             :date             not null
#  description      :string
#  kind             :string           not null
#  time             :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  academic_year_id :bigint           not null
#  company_id       :bigint           not null
#
# Indexes
#
#  index_school_special_days_on_academic_year_id_and_date  (academic_year_id,date)
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#
class SchoolSpecialDay < ApplicationRecord
  include TenantScoped
  include MinuteTime
  audited associated_with: :academic_year

  KINDS = %w[early_dismissal late_dismissal early_arrival late_arrival other].freeze

  belongs_to :academic_year, inverse_of: :special_days

  minute_time :time

  validates :date, presence: true
  validates :kind, inclusion: { in: KINDS }
end

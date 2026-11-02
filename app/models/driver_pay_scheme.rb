# HR > Drivers > Pay Scheme Assignments: the scheme a driver is paid on from a date.
# == Schema Information
#
# Table name: driver_pay_schemes
# Database name: primary
#
#  id            :bigint           not null, primary key
#  ends_on       :date
#  starts_on     :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  driver_id     :bigint           not null
#  pay_scheme_id :bigint           not null
#
# Indexes
#
#  index_driver_pay_schemes_on_company_id               (company_id)
#  index_driver_pay_schemes_on_driver_id_and_starts_on  (driver_id,starts_on) UNIQUE
#  index_driver_pay_schemes_on_pay_scheme_id            (pay_scheme_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (pay_scheme_id => pay_schemes.id)
#
class DriverPayScheme < ApplicationRecord
  include DatedAssignment

  belongs_to :pay_scheme
end

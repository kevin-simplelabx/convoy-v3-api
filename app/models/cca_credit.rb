# Credit for a booked CCA ride the bus did not run, used first at the family's next CCA payment.
# == Schema Information
#
# Table name: cca_credits
# Database name: primary
#
#  id             :bigint           not null, primary key
#  amount         :decimal(12, 2)   not null
#  child_name     :string
#  date           :date             not null
#  reason         :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  cca_booking_id :bigint
#  company_id     :bigint           not null
#  family_id      :bigint           not null
#  school_id      :bigint           not null
#
# Indexes
#
#  index_cca_credits_on_cca_booking_id  (cca_booking_id) UNIQUE
#  index_cca_credits_on_family_id       (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (cca_booking_id => cca_bookings.id) ON DELETE => nullify
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (family_id => families.id)
#  fk_rails_...  (school_id => schools.id)
#
class CcaCredit < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school
  belongs_to :family
  belongs_to :cca_booking, optional: true
end

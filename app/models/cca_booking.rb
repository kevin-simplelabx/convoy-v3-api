# A CCA bus ride a parent booked and paid for (Convoy App): the child, the day, the price paid and the CCA bill. late =
# added after the cut-off while seats were left; not_riding = the parent told the bus (still charged, the seat is freed).
# == Schema Information
#
# Table name: cca_bookings
# Database name: primary
#
#  id              :bigint           not null, primary key
#  child_name      :string           not null
#  class_name      :string
#  date            :date             not null
#  late            :boolean          default(FALSE), not null
#  method          :string           not null
#  not_riding      :boolean          default(FALSE), not null
#  paid_on         :date             not null
#  price           :decimal(12, 2)   not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  family_id       :bigint           not null
#  school_bill_id  :bigint
#  school_id       :bigint           not null
#  school_rider_id :bigint
#
# Indexes
#
#  index_cca_bookings_on_family_id                          (family_id)
#  index_cca_bookings_on_family_id_and_child_name_and_date  (family_id,child_name,date) UNIQUE
#  index_cca_bookings_on_school_bill_id                     (school_bill_id)
#  index_cca_bookings_on_school_id_and_date                 (school_id,date)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (family_id => families.id)
#  fk_rails_...  (school_bill_id => school_bills.id) ON DELETE => nullify
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (school_rider_id => school_riders.id) ON DELETE => nullify
#
class CcaBooking < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school
  belongs_to :family
  belongs_to :school_rider, optional: true
  belongs_to :school_bill, optional: true
  has_one :credit, class_name: "CcaCredit", dependent: :nullify
end

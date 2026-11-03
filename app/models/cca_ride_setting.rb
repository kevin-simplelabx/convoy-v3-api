# CCA Rides of a school: the CCA / ASA bus charged per ride — the price, the weekdays it runs (1 Mon … 5 Fri) and the
# seats a day. Parents book next week in the Convoy App by Saturday 23:59.
# == Schema Information
#
# Table name: cca_ride_settings
# Database name: primary
#
#  id          :bigint           not null, primary key
#  days        :integer          default([2, 4]), not null, is an Array
#  enabled     :boolean          default(FALSE), not null
#  price       :decimal(12, 2)   default(0.0), not null
#  seats       :integer          default(40), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint           not null
#  saved_by_id :bigint
#  school_id   :bigint           not null
#
# Indexes
#
#  index_cca_ride_settings_on_school_id  (school_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (saved_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#
class CcaRideSetting < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school
  belongs_to :saved_by, class_name: "User", optional: true
end

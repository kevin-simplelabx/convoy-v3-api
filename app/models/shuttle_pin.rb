# A route a staff rider pinned: Pinned chip and first in the list.
# == Schema Information
#
# Table name: shuttle_pins
# Database name: primary
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint           not null
#  company_id     :bigint           not null
#  trip_id        :bigint           not null
#
# Indexes
#
#  index_shuttle_pins_on_app_account_id              (app_account_id)
#  index_shuttle_pins_on_app_account_id_and_trip_id  (app_account_id,trip_id) UNIQUE
#  index_shuttle_pins_on_company_id                  (company_id)
#  index_shuttle_pins_on_trip_id                     (trip_id)
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id) ON DELETE => cascade
#
class ShuttlePin < ApplicationRecord
  include TenantScoped

  belongs_to :app_account
  belongs_to :trip
end

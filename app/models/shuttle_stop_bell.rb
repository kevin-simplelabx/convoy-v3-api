# The bell on a stop of a route (all timings of one direction); `on` false = switched off a stop that would be on by default
# (the usual boarding stop).
# == Schema Information
#
# Table name: shuttle_stop_bells
# Database name: primary
#
#  id             :bigint           not null, primary key
#  direction      :integer          not null
#  on             :boolean          default(TRUE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint           not null
#  company_id     :bigint           not null
#  trip_id        :bigint           not null
#  trip_stop_id   :bigint           not null
#
# Indexes
#
#  index_shuttle_stop_bells_on_app_account_id  (app_account_id)
#  index_shuttle_stop_bells_on_company_id      (company_id)
#  index_shuttle_stop_bells_on_trip_id         (trip_id)
#  index_shuttle_stop_bells_on_trip_stop_id    (trip_stop_id)
#  index_shuttle_stop_bells_unique             (app_account_id,trip_id,direction,trip_stop_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id) ON DELETE => cascade
#  fk_rails_...  (trip_stop_id => trip_stops.id) ON DELETE => cascade
#
class ShuttleStopBell < ApplicationRecord
  include TenantScoped

  belongs_to :app_account
  belongs_to :trip
  belongs_to :trip_stop

  validates :direction, inclusion: { in: [ 1, 2 ] }
end

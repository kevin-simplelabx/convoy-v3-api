# My Usual Shuttle: the run a staff rider takes most days, one per employer (client): the route, the timing (a trip run, so it
# survives regeneration) and the stop they board at. Deleting the run or stop in Convoy OS removes it ("Choose again").
# == Schema Information
#
# Table name: shuttle_usuals
# Database name: primary
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  app_account_id :bigint           not null
#  client_id      :bigint           not null
#  company_id     :bigint           not null
#  trip_id        :bigint           not null
#  trip_run_id    :bigint           not null
#  trip_stop_id   :bigint           not null
#
# Indexes
#
#  index_shuttle_usuals_on_app_account_id                (app_account_id)
#  index_shuttle_usuals_on_app_account_id_and_client_id  (app_account_id,client_id) UNIQUE
#  index_shuttle_usuals_on_client_id                     (client_id)
#  index_shuttle_usuals_on_company_id                    (company_id)
#  index_shuttle_usuals_on_trip_id                       (trip_id)
#  index_shuttle_usuals_on_trip_run_id                   (trip_run_id)
#  index_shuttle_usuals_on_trip_stop_id                  (trip_stop_id)
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id) ON DELETE => cascade
#  fk_rails_...  (trip_run_id => trip_runs.id) ON DELETE => cascade
#  fk_rails_...  (trip_stop_id => trip_stops.id) ON DELETE => cascade
#
class ShuttleUsual < ApplicationRecord
  include TenantScoped
  audited associated_with: :client

  belongs_to :client
  belongs_to :app_account
  belongs_to :trip
  belongs_to :trip_run
  belongs_to :trip_stop

  validate :run_and_stop_belong_to_trip

  private

  def run_and_stop_belong_to_trip
    errors.add(:trip_run, "is not a timing of this route") if trip_run && trip_run.trip_id != trip_id
    errors.add(:trip_stop, "is not a stop of this route") if trip_stop && trip_stop.trip_id != trip_id
  end
end

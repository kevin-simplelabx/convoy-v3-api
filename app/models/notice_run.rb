# == Schema Information
#
# Table name: notice_runs
# Database name: primary
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint           not null
#  notice_id   :bigint           not null
#  trip_run_id :bigint           not null
#
# Indexes
#
#  index_notice_runs_on_company_id                 (company_id)
#  index_notice_runs_on_notice_id                  (notice_id)
#  index_notice_runs_on_notice_id_and_trip_run_id  (notice_id,trip_run_id) UNIQUE
#  index_notice_runs_on_trip_run_id                (trip_run_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (notice_id => notices.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#
class NoticeRun < ApplicationRecord
  include TenantScoped

  belongs_to :notice, inverse_of: :runs
  belongs_to :trip_run
end

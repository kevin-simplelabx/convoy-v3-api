# == Schema Information
#
# Table name: schools
# Database name: primary
#
#  id          :bigint           not null, primary key
#  address     :text
#  lat         :decimal(10, 7)
#  lng         :decimal(10, 7)
#  name        :string           not null
#  short_name  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  calendar_id :bigint
#  client_id   :bigint
#  company_id  :bigint           not null
#
# Indexes
#
#  index_schools_on_calendar_id          (calendar_id)
#  index_schools_on_client_id            (client_id)
#  index_schools_on_company_id           (company_id)
#  index_schools_on_company_id_and_name  (company_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (calendar_id => calendars.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#
# A school whose buses we run (School Bus). The Scheduler shows its routes; its calendar moves and stops them.
class School < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :client, optional: true
  belongs_to :calendar, optional: true
  has_many :plans, class_name: "SchoolPlan", dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :company_id }

  def short = short_name.presence || name
end

# == Schema Information
#
# Table name: maintenance_invoices
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  file                 :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_id           :bigint           not null
#  maintenance_visit_id :bigint           not null
#
# Indexes
#
#  index_maintenance_invoices_on_company_id            (company_id)
#  index_maintenance_invoices_on_maintenance_visit_id  (maintenance_visit_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (maintenance_visit_id => maintenance_visits.id)
#
class MaintenanceInvoice < ApplicationRecord
  include TenantScoped

  mount_uploader :file, DocumentUploader

  belongs_to :visit, class_name: "MaintenanceVisit", foreign_key: :maintenance_visit_id, inverse_of: :invoices

  validates :file, presence: true
end

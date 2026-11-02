# == Schema Information
#
# Table name: vehicle_insurance_documents
# Database name: primary
#
#  id                          :bigint           not null, primary key
#  file                        :string           not null
#  kind                        :string           default("other"), not null
#  plate_differs               :boolean          default(FALSE), not null
#  plate_on_document           :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  company_id                  :bigint           not null
#  vehicle_insurance_policy_id :bigint           not null
#
# Indexes
#
#  idx_on_vehicle_insurance_policy_id_83c63fa225    (vehicle_insurance_policy_id)
#  index_vehicle_insurance_documents_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (vehicle_insurance_policy_id => vehicle_insurance_policies.id)
#
# An insurance file (policy schedule, Certificate of Insurance, premium debit note) on a policy; up to 5 per policy.
class VehicleInsuranceDocument < ApplicationRecord
  include TenantScoped
  audited associated_with: :policy

  KINDS = %w[policy certificate invoice other].freeze
  KIND_NAMES = { "policy" => "Policy", "certificate" => "Certificate of Insurance", "invoice" => "Premium invoice", "other" => "Document" }.freeze

  mount_uploader :file, DocumentUploader

  belongs_to :policy, class_name: "VehicleInsurancePolicy", foreign_key: :vehicle_insurance_policy_id, inverse_of: :documents

  validates :file, presence: true
  validates :kind, inclusion: { in: KINDS }
  validate :within_limit, on: :create

  def kind_name = KIND_NAMES[kind]

  private

  def within_limit
    return if policy.nil? || policy.documents.where.not(id: nil).count < VehicleInsurancePolicy::MAX_DOCUMENTS

    errors.add(:base, "A policy keeps up to #{VehicleInsurancePolicy::MAX_DOCUMENTS} files")
  end
end

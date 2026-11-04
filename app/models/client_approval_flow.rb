# A client's approval flow (Client Portal › Settings › Approval Flows): the organisation's (no site) or a site's own.
# A booking for a site whose own flow is on follows only that flow; other bookings follow the organisation's.
# == Schema Information
#
# Table name: client_approval_flows
# Database name: primary
#
#  id             :bigint           not null, primary key
#  on             :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  client_id      :bigint           not null
#  client_site_id :bigint
#  company_id     :bigint           not null
#
# Indexes
#
#  index_client_approval_flows_on_client_id_and_client_site_id  (client_id,client_site_id) UNIQUE NULLS NOT DISTINCT
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id) ON DELETE => cascade
#  fk_rails_...  (client_site_id => client_sites.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#
class ClientApprovalFlow < ApplicationRecord
  include TenantScoped
  audited associated_with: :client
  has_associated_audits

  belongs_to :client
  belongs_to :client_site, optional: true
  has_many :rules, -> { order(:position, :id) }, class_name: "ClientApprovalRule", inverse_of: :flow, dependent: :destroy

  # The flow for a client and site (nil = the organisation) to show: the saved one, else an unsaved one (off, no rules).
  def self.for(client, site) = find_by(client:, client_site: site) || new(client:, client_site: site, company_id: client.company_id)

  # The flow to change, made (off, Otherwise with no steps) the first time.
  def self.for!(client, site)
    flow = find_or_create_by!(client:, client_site: site) { it.company_id = client.company_id }
    flow.otherwise
    flow
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def organisation? = client_site_id.nil?
  def ordered_rules = rules.reject(&:otherwise?)

  def otherwise
    rules.find_by(otherwise: true) || rules.create!(company_id:, otherwise: true, position: 0)
  end
end

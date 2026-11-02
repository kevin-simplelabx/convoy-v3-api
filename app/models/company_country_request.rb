# Company Settings > Request a Country Change: sent by a company user with the Users permission, decided by a
# Convoy Admin (approve moves the company; decline keeps it), or withdrawn by the company. One pending per company.
# == Schema Information
#
# Table name: company_country_requests
# Database name: primary
#
#  id              :bigint           not null, primary key
#  decided_at      :datetime
#  from_country    :string           not null
#  reason          :text             not null
#  status          :string           default("pending"), not null
#  to_country      :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  decided_by_id   :bigint
#  requested_by_id :bigint
#
# Indexes
#
#  index_company_country_requests_on_company_id_and_created_at  (company_id,created_at)
#  index_company_country_requests_on_decided_by_id              (decided_by_id)
#  index_company_country_requests_on_requested_by_id            (requested_by_id)
#  index_company_country_requests_on_status_and_created_at      (status,created_at)
#  index_company_country_requests_one_pending                   (company_id) UNIQUE WHERE ((status)::text = 'pending'::text)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (decided_by_id => users.id)
#  fk_rails_...  (requested_by_id => users.id)
#
class CompanyCountryRequest < ApplicationRecord
  audited

  belongs_to :company
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :decided_by, class_name: "User", optional: true

  enum :status, { pending: "pending", approved: "approved", declined: "declined", withdrawn: "withdrawn" }, validate: true

  normalizes :to_country, with: ->(v) { v.to_s.strip.upcase }
  normalizes :reason, with: ->(v) { v.to_s.strip }

  validates :to_country, inclusion: { in: ->(_) { Country.live_codes }, message: "is not open yet" }
  validates :reason, presence: true
  validate :not_the_same, :one_pending, on: :create

  before_validation(on: :create) { self.from_country ||= company&.country }

  def approve!(user:)
    transaction do
      company.update!(country: to_country, country_set_at: Time.current, country_set_by: user)
      update!(status: :approved, decided_by: user, decided_at: Time.current)
    end
  end

  def decline!(user:) = update!(status: :declined, decided_by: user, decided_at: Time.current)
  def withdraw!(user:) = update!(status: :withdrawn, decided_by: user, decided_at: Time.current)

  private

  def not_the_same
    errors.add(:to_country, "is where the company is already (#{Country.find(to_country)&.name})") if to_country.present? && to_country == from_country
  end

  def one_pending
    errors.add(:base, "A change is already waiting for Convoy") if company && CompanyCountryRequest.pending.exists?(company_id: company.id)
  end
end

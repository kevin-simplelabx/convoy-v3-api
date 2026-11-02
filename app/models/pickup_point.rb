# == Schema Information
#
# Table name: pickup_points
# Database name: primary
#
#  id           :bigint           not null, primary key
#  lat          :decimal(10, 7)
#  lng          :decimal(10, 7)
#  name         :string           not null
#  note         :text
#  postal_codes :string           default([]), not null, is an Array
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint           not null
#
# Indexes
#
#  index_pickup_points_on_company_id    (company_id)
#  index_pickup_points_on_postal_codes  (postal_codes) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A Saved Pick-up Point: the postal codes that share one stop (a condominium's gate), with its name, pin and a note.
# Rows of an imported route list whose postal codes share a point join one stop and take its name, pin and note.
class PickupPoint < ApplicationRecord
  include TenantScoped
  include TagList
  audited

  tag_list :postal_codes

  validates :name, presence: true
  validate { errors.add(:postal_codes, "must be 6 digits") if postal_codes.any? { |p| !p.match?(/\A\d{6}\z/) } }

  def self.for_postal(code) = code.present? ? where("? = ANY(postal_codes)", code).first : nil
end

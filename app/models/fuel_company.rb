# A fuel or charging company picked on fuel entries (Fuel Companies window), per company. Singapore defaults are added
# the first time the list is used; one in use by an entry can't be deleted.
# == Schema Information
#
# Table name: fuel_companies
# Database name: primary
#
#  id         :bigint           not null, primary key
#  kind       :string           default("fuel"), not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_fuel_companies_on_company_and_name  (company_id, lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class FuelCompany < ApplicationRecord
  include TenantScoped
  audited

  DEFAULTS = [ [ "Esso", "fuel" ], [ "Shell", "fuel" ], [ "SPC", "fuel" ], [ "Caltex", "fuel" ], [ "Sinopec", "fuel" ],
               [ "SP Mobility", "elec" ], [ "Shell Recharge", "elec" ], [ "Charge+", "elec" ], [ "TotalEnergies", "elec" ] ].freeze

  # Deleting one in use is refused by FuelCompanies::Save (and the foreign key).
  has_many :entries, class_name: "FuelEntry", dependent: nil

  enum :kind, { fuel: "fuel", elec: "elec", both: "both" }, validate: true

  normalizes :name, with: ->(v) { v.to_s.squish }

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }

  default_scope { order(:position, :id) }

  def self.ensure_defaults!
    return if exists?

    DEFAULTS.each_with_index { |(name, kind), i| create!(name:, kind:, position: i) }
  end

  # The company named on a receipt: the same name, or the longest name it contains ("Esso Jurong West" → Esso).
  def self.named_in(text)
    t = text.to_s.downcase.squish
    return if t.blank?

    all.to_a.sort_by { |c| -c.name.length }.then { |cs| cs.find { |c| c.name.downcase == t } || cs.find { |c| t.include?(c.name.downcase) } }
  end
end

# What a driver shares from the Convoy Driver app: contact, personal details, driving and vocational licence.
# Only the driver changes it (the app writes it; seeds for now) and it goes when they stop sharing.
# The NRIC / FIN is encrypted; id_number_masked (S****123A) is what lists show.
# == Schema Information
#
# Table name: driver_kyc_profiles
# Database name: primary
#
#  id                            :bigint           not null, primary key
#  address                       :text
#  date_of_birth                 :date
#  driver_type                   :string           not null
#  email                         :string
#  id_number                     :string
#  id_number_masked              :string
#  licence_class                 :string
#  licence_qualified_on          :date
#  licences                      :jsonb            not null
#  nationality                   :string
#  residential_status            :string
#  shared_at                     :datetime
#  vocational_licence_expires_on :date
#  vocational_licence_number     :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  company_id                    :bigint           not null
#  driver_id                     :bigint           not null
#
# Indexes
#
#  idx_on_company_id_vocational_licence_expires_on_68d32c5ee3  (company_id,vocational_licence_expires_on)
#  index_driver_kyc_profiles_on_company_id                     (company_id)
#  index_driver_kyc_profiles_on_driver                         (driver_type,driver_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class DriverKycProfile < ApplicationRecord
  include TenantScoped
  audited

  # Vocational licence (BDVL) shown in orange when it ends within this many days.
  EXPIRY_WARNING_DAYS = 90

  belongs_to :driver, polymorphic: true

  encrypts :id_number

  before_save { self.id_number_masked = self.class.mask(id_number) if id_number_changed? }

  # S1234567A → S****567A
  def self.mask(number)
    n = number.to_s.strip.upcase
    n.length < 5 ? n.presence : "#{n[0]}****#{n[-4..]}"
  end

  def age(on = Date.current)
    return unless date_of_birth

    had_birthday = on.strftime("%m%d") >= date_of_birth.strftime("%m%d")
    on.year - date_of_birth.year - (had_birthday ? 0 : 1)
  end

  # expired | due_soon | valid | nil
  def vocational_status(on = Date.current)
    return unless vocational_licence_expires_on

    days = (vocational_licence_expires_on - on).to_i
    days.negative? ? "expired" : (days <= EXPIRY_WARNING_DAYS ? "due_soon" : "valid")
  end

  # FIN for work permit holders, else NRIC.
  def id_label = residential_status.to_s.match?(/work permit|employment pass|s pass/i) ? "FIN" : "NRIC"
end

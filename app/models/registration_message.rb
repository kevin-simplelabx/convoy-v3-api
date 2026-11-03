# One of the 12 parent messages of a Bus Service Registration (config/presets/registration_messages.yml): on / off,
# channels, timing (days from its anchor date, or hours before an offer lapses) and the texts. The welcome message waits
# for a Release Now unless scheduled.
# == Schema Information
#
# Table name: registration_messages
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  app                    :boolean          default(TRUE), not null
#  body                   :text
#  email                  :boolean          default(TRUE), not null
#  enabled                :boolean          default(TRUE), not null
#  key                    :string           not null
#  offset_days            :integer
#  offset_hours           :integer
#  released_at            :timestamptz
#  subject                :string
#  whatsapp               :boolean          default(TRUE), not null
#  whatsapp_body          :text
#  school_registration_id :bigint           not null
#
# Indexes
#
#  index_registration_messages_on_school_registration_id_and_key  (school_registration_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_registration_id => school_registrations.id) ON DELETE => cascade
#
class RegistrationMessage < ApplicationRecord
  audited associated_with: :school_registration

  PRESETS = YAML.load_file(Rails.root.join("config/presets/registration_messages.yml")).map(&:symbolize_keys).index_by { it[:key] }.freeze

  belongs_to :school_registration, inverse_of: :messages

  validates :key, inclusion: { in: PRESETS.keys }, uniqueness: { scope: :school_registration_id }

  def preset = PRESETS.fetch(key)
end

# An invite (or resend) to an own or operator driver's mobile. Only recorded for now: delivery stays "recorded"
# until an SMS sender is set up.
# == Schema Information
#
# Table name: driver_invites
# Database name: primary
#
#  id             :bigint           not null, primary key
#  delivery       :string           default("recorded"), not null
#  invitable_type :string           not null
#  kind           :string           default("invite"), not null
#  message        :text             not null
#  phone          :string           not null
#  created_at     :datetime         not null
#  company_id     :bigint           not null
#  invitable_id   :bigint           not null
#  sent_by_id     :bigint
#
# Indexes
#
#  index_driver_invites_on_company_id  (company_id)
#  index_driver_invites_on_invitable   (invitable_type,invitable_id)
#  index_driver_invites_on_sent_by_id  (sent_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (sent_by_id => users.id)
#
class DriverInvite < ApplicationRecord
  include TenantScoped

  belongs_to :invitable, polymorphic: true
  belongs_to :sent_by, class_name: "User", optional: true

  enum :kind, { invite: "invite", resend: "resend" }, validate: true

  validates :phone, :message, presence: true
end

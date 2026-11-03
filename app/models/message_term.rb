# == Schema Information
#
# Table name: message_terms
# Database name: primary
#
#  id            :bigint           not null, primary key
#  kind          :string           default("oth"), not null
#  means         :text             not null
#  term          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :bigint
#
# Indexes
#
#  index_message_terms_on_created_by_id  (created_by_id)
#  index_message_terms_on_lower_term     (lower((term)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#
# A word or short form read with every trip message (platform-wide). Edited by Convoy Admin (screen not built yet).
class MessageTerm < ApplicationRecord
  KINDS = { "veh" => "Vehicle", "svc" => "Service", "place" => "Place", "oth" => "Other" }.freeze

  belongs_to :created_by, class_name: "User", optional: true

  normalizes :term, :means, with: ->(v) { v.to_s.squish }

  validates :term, presence: true, uniqueness: { case_sensitive: false, message: "is already on the list" }
  validates :means, presence: true
  validates :kind, inclusion: { in: KINDS.keys }
end

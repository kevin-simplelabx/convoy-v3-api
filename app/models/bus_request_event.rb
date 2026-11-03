# One line of a Bus Service Request's history: when, who (Parent, or a Convoy OS user) and what happened.
# == Schema Information
#
# Table name: bus_request_events
# Database name: primary
#
#  id             :bigint           not null, primary key
#  at             :timestamptz      not null
#  by_name        :string           not null
#  text           :text             not null
#  bus_request_id :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_bus_request_events_on_bus_request_id  (bus_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (bus_request_id => bus_requests.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class BusRequestEvent < ApplicationRecord
  belongs_to :bus_request, inverse_of: :events
  belongs_to :user, optional: true

  validates :text, :by_name, :at, presence: true
end

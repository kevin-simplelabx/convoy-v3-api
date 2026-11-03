# A mid-year request's answer date moved, with the reason the parent sees.
# == Schema Information
#
# Table name: bus_request_answer_moves
# Database name: primary
#
#  id             :bigint           not null, primary key
#  from_date      :date
#  moved_at       :timestamptz      not null
#  reason         :string           not null
#  to_date        :date             not null
#  bus_request_id :bigint           not null
#  moved_by_id    :bigint
#
# Indexes
#
#  index_bus_request_answer_moves_on_bus_request_id  (bus_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (bus_request_id => bus_requests.id) ON DELETE => cascade
#  fk_rails_...  (moved_by_id => users.id) ON DELETE => nullify
#
class BusRequestAnswerMove < ApplicationRecord
  belongs_to :bus_request, inverse_of: :answer_moves
  belongs_to :moved_by, class_name: "User", optional: true

  validates :to_date, :reason, :moved_at, presence: true
end

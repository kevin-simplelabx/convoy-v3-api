# Different Timing of a bus session on some of its days.
# == Schema Information
#
# Table name: bus_session_variants
# Database name: primary
#
#  id             :bigint           not null, primary key
#  arrive_from    :integer
#  arrive_to      :integer
#  days           :integer          default([]), not null, is an Array
#  depart         :integer
#  dismissal      :integer
#  position       :integer          not null
#  bus_session_id :bigint           not null
#
# Indexes
#
#  index_bus_session_variants_on_bus_session_id_and_position  (bus_session_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (bus_session_id => bus_sessions.id) ON DELETE => cascade
#
class BusSessionVariant < ApplicationRecord
  include MinuteTime

  belongs_to :bus_session, inverse_of: :variants

  minute_time :arrive_from, :arrive_to, :dismissal, :depart
end

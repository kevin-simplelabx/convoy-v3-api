# A row of a step's named people (removed with the user it names).
# == Schema Information
#
# Table name: client_approval_step_people
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  client_approval_step_id :bigint           not null
#  client_user_id          :bigint           not null
#
# Indexes
#
#  index_client_approval_step_people_on_client_user_id  (client_user_id)
#  index_client_approval_step_people_unique             (client_approval_step_id,client_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (client_approval_step_id => client_approval_steps.id) ON DELETE => cascade
#  fk_rails_...  (client_user_id => client_users.id) ON DELETE => cascade
#
class ClientApprovalStepPerson < ApplicationRecord
  self.table_name = "client_approval_step_people"

  belongs_to :client_approval_step
  belongs_to :client_user
end

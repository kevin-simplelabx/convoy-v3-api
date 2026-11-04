# A verified mobile (or email) that moved from one Convoy App account to another: numbers get reissued, so whoever
# verifies it now takes it, and nothing else comes with it. The old owner is told by email when they have one.
# == Schema Information
#
# Table name: app_identity_moves
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  kind                :string           not null
#  moved_at            :datetime         not null
#  value               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  from_app_account_id :bigint
#  to_app_account_id   :bigint
#
# Indexes
#
#  index_app_identity_moves_on_from_app_account_id  (from_app_account_id)
#  index_app_identity_moves_on_to_app_account_id    (to_app_account_id)
#  index_app_identity_moves_on_value                (value)
#
# Foreign Keys
#
#  fk_rails_...  (from_app_account_id => app_accounts.id) ON DELETE => nullify
#  fk_rails_...  (to_app_account_id => app_accounts.id) ON DELETE => nullify
#
class AppIdentityMove < ApplicationRecord
  belongs_to :from_app_account, class_name: "AppAccount", optional: true
  belongs_to :to_app_account, class_name: "AppAccount", optional: true
end

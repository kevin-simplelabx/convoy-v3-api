# HR > Rewards: what drivers redeem points for (photo, title, description, points needed, active / inactive).
module Api
  module V1
    class PayRewardsController < BaseController
      def index
        authorize PayReward
        render_list policy_scope(PayReward).kept.order(:points_required, :title), PayRewardBlueprint
      end

      def show
        render_data authorize(find_reward), PayRewardBlueprint
      end

      # POST /pay/rewards (multipart with a photo) { reward: { title, description, points_required, status, photo } }
      def create
        reward = authorize PayReward.new(reward_params)
        reward.audit_comment = "Created the reward, #{reward.points_required} points, #{reward.status}"
        reward.save!
        render_data reward, PayRewardBlueprint, status: :created
      end

      def update
        reward = authorize find_reward
        reward.update!(reward_params)
        render_data reward, PayRewardBlueprint
      end

      def destroy
        reward = authorize find_reward
        reward.discard!
        reward.audits.create!(action: "destroy", audited_changes: { "title" => reward.title })
        head :no_content
      end

      private

      def find_reward = policy_scope(PayReward).kept.find(params[:id])

      def reward_params = params.expect(reward: %i[title description points_required status photo remove_photo])
    end
  end
end

# Who did something on the booking tables (decision 04/11/2026): a Convoy OS user (<x>_by: staff, or recording a step for
# the client), or a client user in the Client Portal (<x>_by_client_user), never both; and the name kept for display
# (<x>_by_name, where the table has it: the actor's name, or the client's person when we record for them).
module ActorStamp
  extend ActiveSupport::Concern

  class_methods do
    # actor_stamp :acknowledged → acknowledged_by (User), acknowledged_by_client_user, #acknowledged_by_kind.
    def actor_stamp(*actions)
      actions.each do |a|
        belongs_to :"#{a}_by", class_name: "User", optional: true unless reflect_on_association(:"#{a}_by")
        belongs_to :"#{a}_by_client_user", class_name: "ClientUser", optional: true
        define_method(:"#{a}_by_kind") do
          if self[:"#{a}_by_client_user_id"] then "client_user"
          elsif self[:"#{a}_by_id"] then "user"
          end
        end
      end
    end
  end

  # Records that actor (a User or a ClientUser) did action; name: the name to keep, else the actor's.
  def stamp_actor(action, actor, name: nil)
    self[:"#{action}_by_id"] = (actor.id if actor.is_a?(User))
    self[:"#{action}_by_client_user_id"] = (actor.id if actor.is_a?(ClientUser))
    column = "#{action}_by_name"
    self[column] = name.presence || actor_name(actor) if has_attribute?(column)
    self
  end

  private

  def actor_name(actor) = actor.respond_to?(:shown_name) ? actor.shown_name : actor&.name
end

# A booking's approval as the booking detail draws it (stages: Booking Submitted → each step → Sent to <company>), for
# a viewer: each step's state (done, wait, no, up), its people (approved, carried, declined, waiting, will be asked, no
# longer asked: removed, or their role or sites changed), who it waits for, and whether the viewer may decide (or step in).
module Portal
  class ApprovalView
    def self.call(approval, viewer: nil)
      state = Approval.new(approval)
      new(state, viewer).call
    end

    def initialize(state, viewer)
      @state = state
      @a = state.approval
      @viewer = viewer
    end

    def call
      waiting = @state.waiting_for
      { status: @a.status, name: @a.name, flow: @a.flow_kind, same_person: @a.same_person, current_step: @a.waiting? ? @a.current_step : nil,
        steps_count: @a.steps.size, sent_at: @a.created_at, decided_at: @a.decided_at,
        waiting_for: waiting.map { { id: it.id, name: it.name } },
        waiting_text: @a.waiting? ? "Waiting for #{list(waiting.map(&:name))} (step #{@a.current_step} of #{@a.steps.size})" : nil,
        can_decide: @viewer ? @state.can_decide?(@viewer) : false, stepping_in: @viewer ? @state.stepping_in?(@viewer) : false,
        steps: @a.steps.map { step(it) } }
    end

    private

    def step(s)
      acts = @state.acts_on(s)
      right = @state.people(s).map(&:id)
      { position: s.position, label: s.label, who: s.who, need: s.need, fallback: s.fallback, state: step_state(s, acts),
        acts: acts.map { { id: it.id, by: { id: it.client_user_id, name: it.client_user.name }, act: it.act, note: it.note, carried_from: it.carried_from, at: it.created_at } },
        people: s.step_people.map do |p|
          act = acts.find { it.client_user_id == p.client_user_id }
          { id: p.client_user_id, name: p.client_user.name, state: person_state(s, act, right.include?(p.client_user_id)) }
        end }
    end

    def step_state(s, acts)
      return "no" if acts.any? { !it.approve? }
      return "done" if s.position < @a.current_step || @a.status == "ok"
      return "wait" if @a.waiting? && s.position == @a.current_step

      "up"
    end

    def person_state(s, act, right)
      return act.carried_from ? "carried" : "approved" if act&.approve?
      return "declined" if act
      return "no_longer" unless right
      return "waiting" if @a.waiting? && s.position == @a.current_step

      s.position > @a.current_step && @a.waiting? ? "will_be_asked" : "not_asked"
    end

    def list(names) = names.size <= 2 ? names.join(" or ") : "#{names[0..-2].join(', ')} or #{names.last}"
  end
end

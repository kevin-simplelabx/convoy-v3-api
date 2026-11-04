# Client Portal › Settings › Approval Flows. `:for` is "organisation" or a site id (that site's own flow). Rules are
# checked from the top; Otherwise takes the rest; Try a Booking shows where a booking would go (nothing saved).
module Api
  module V1
    module Portal
      class ApprovalFlowsController < AppController
        # GET /portal/approval_flows → the flows the person sets (Flow For pills: Whole Organisation, then their sites)
        def index
          authorize_portal ClientApprovalFlow
          flows = ([ nil ] if current_client_user.wide?).to_a + current_client_user.limit_to_sites(current_client.sites, :id).order(:name).to_a
          render json: { data: flows.map { ::Portal::ApprovalFlowView.call(flow: ClientApprovalFlow.for(current_client, it)) } }
        end

        # PATCH /portal/approval_flows/:for { on }
        def update
          flow = authorize_flow
          flow.update!(on: ActiveModel::Type::Boolean.new.cast(params.require(:on)))
          render_flow flow
        end

        # PATCH /portal/approval_flows/:for/otherwise { rule: { steps: [{ who: [], people_ids: [], need }], same_person } }
        def otherwise
          flow = authorize_flow
          ::Portal::SaveApprovalRule.call(flow:, rule: flow.otherwise, params: rule_params)
          render_flow flow
        end

        # POST /portal/approval_flows/:for/rules { rule: { name, when: { site_ids, booker_ids, team_ids, kinds, over, lead_days }, steps, same_person } }
        def create_rule
          flow = authorize_flow
          ::Portal::SaveApprovalRule.call(flow:, params: rule_params)
          render_flow flow, status: :created
        end

        # PATCH /portal/approval_flows/:for/rules/:id
        def update_rule
          flow = authorize_flow
          ::Portal::SaveApprovalRule.call(flow:, rule: find_rule(flow), params: rule_params)
          render_flow flow
        end

        # DELETE /portal/approval_flows/:for/rules/:id
        def destroy_rule
          flow = authorize_flow
          find_rule(flow).destroy!
          render_flow flow
        end

        # POST /portal/approval_flows/:for/rules/:id/move { direction: "up" | "down" }
        def move_rule
          flow = authorize_flow
          rules = flow.ordered_rules
          i = rules.index { it.id == find_rule(flow).id }
          j = params.require(:direction) == "up" ? i - 1 : i + 1
          if j.between?(0, rules.size - 1)
            rules[i], rules[j] = rules[j], rules[i]
            ClientApprovalRule.transaction { rules.each_with_index { |r, k| r.update!(position: k + 1) } }
          end
          render_flow flow
        end

        # POST /portal/approval_flows/try { site_id, booked_by_id, kind, estimate, lead_days } (Try a Booking)
        def try_booking
          authorize_portal ClientApprovalFlow, :try_booking?
          booker = params[:booked_by_id].presence && current_client.users.kept.find(params[:booked_by_id])
          site_id = params[:site_id].presence&.to_i
          raise ActiveRecord::RecordNotFound if site_id && !current_client.sites.exists?(site_id)

          result = ::Portal::ApprovalRoute.call(client: current_client, booking: {
            site_id:, booker:, kinds: Array(params[:kind].presence), amount: params[:estimate].to_d,
            lead: params[:lead_days].presence&.to_i
          })
          render json: { data: result.to_h }
        end

        private

        def authorize_flow
          site = params[:for] == "organisation" ? nil : current_client.sites.find(params[:for])
          authorize_portal ClientApprovalFlow.for!(current_client, site), :update?
        end

        def find_rule(flow) = ClientApprovalRule.where(flow:, otherwise: false).find(params[:id])

        def rule_params
          params.expect(rule: [ :name, :same_person, { when: [ :over, :lead_days, { site_ids: [], booker_ids: [], team_ids: [], kinds: [] } ],
                                               steps: [ [ :need, { who: [], people_ids: [] } ] ] } ])
        end

        def render_flow(flow, status: :ok)
          render json: { data: ::Portal::ApprovalFlowView.call(flow: flow.reload) }, status:
        end
      end
    end
  end
end

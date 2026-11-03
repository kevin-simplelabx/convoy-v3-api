# Convoy Admin > Company Leads: the asks from the Convoy App grouped by work email domain (most asks first), with
# Convoy's status and note per domain. Tabs: Open (not signed up or lost), Signed Up, Not Interested.
module Api
  module V1
    class CompanyLeadsController < BaseController
      skip_before_action :assign_tenant

      # GET /leads?tab=open|signed|lost
      def index
        authorize :platform, :index?
        acts = CompanyLeadDomain.includes(:updated_by).index_by(&:domain)
        groups = CompanyLead.order(asked_at: :desc).group_by(&:domain).map { |dom, asks| row(dom, asks, acts[dom]) }
        tab = params[:tab].presence_in(%w[open signed lost]) || "open"
        in_tab = ->(r, t) { t == "open" ? !%w[signed lost].include?(r[:status]) : r[:status] == t }
        rows = groups.select { |r| in_tab.(r, tab) }.sort_by { |r| [ -r[:asks].size, -r[:last_asked_at].to_i ] }
        render json: { data: rows, meta: { tab:, counts: %w[open signed lost].index_with { |t| groups.count { |r| in_tab.(r, t) } },
                                           statuses: CompanyLeadDomain::STATUSES } }
      end

      # PATCH /leads/:id (the domain, e.g. acme.com.sg) { status, note }
      def update
        authorize :platform, :update?
        dom = params[:id].to_s.downcase
        raise ActiveRecord::RecordNotFound unless CompanyLead.exists?(domain: dom)

        act = CompanyLeadDomain.find_or_initialize_by(domain: dom)
        act.update!(params.permit(:status, :note).merge(updated_by: current_user))
        render json: { data: row(dom, CompanyLead.where(domain: dom).order(asked_at: :desc).to_a, act) }
      end

      private

      def row(dom, asks, act)
        company = asks.group_by(&:company_name).max_by { |_, l| l.size }&.first || dom
        { domain: dom, company:, status: act&.status || "new", status_label: CompanyLeadDomain::STATUSES[act&.status || "new"], note: act&.note,
          updated_by: act&.updated_by&.name, updated_at: act&.updated_at, last_asked_at: asks.first.asked_at,
          contacts_given: asks.count { |a| a.contact.present? }, named: asks.count { |a| a.named_name.present? },
          asks: asks.map { |a| { asked_at: a.asked_at, company: a.company_name, contact: a.contact, who: a.named_name && { name: a.named_name, via: a.named_via }, source: a.source } } }
      end
    end
  end
end

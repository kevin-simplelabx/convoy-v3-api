# Convoy App › CCA Bus per ride. Any adult of the Family looks, picks days, sets Same Days Every Week and says Not Riding;
# paying (Pay to confirm) is the Billing Contact's.
module Api
  module V1
    module ConvoyApp
      class CcaController < SchoolBaseController
        before_action :require_billing!, only: :create

        # GET /app/cca?school_id=&tab=next|this → { schools, school, price, rule, credit, deadline, kids[days], methods, can_pay } ({ schools: [] } when none)
        def show
          render json: { data: ::ConvoyApp::Cca::Week.call(member: current_member, school_id: params[:school_id], tab: params[:tab]) }
        end

        # POST /app/cca/quote { school_id, picks: [{ dependant_id, date }], method } → rows, credit, admin fee, total
        def quote
          render json: { data: ::ConvoyApp::Cca::Quote.call(member: current_member, **payment_args) }
        end

        # POST /app/cca/payments { school_id, picks, method } → { rides, paid, invoice, week } (201)
        def create
          r = ::ConvoyApp::Cca::Pay.call(member: current_member, **payment_args)
          week = ::ConvoyApp::Cca::Week.call(member: current_member, school_id: params[:school_id])
          invoice = ::ConvoyApp::Parents.within(r.company) { { id: r.bill.id, number: r.bill.number, period: r.bill.period_label, total: r.bill.total } }
          render json: { data: { rides: r.rides, paid: r.charge&.charged || 0.to_d, admin_fee: r.charge&.admin_fee || 0.to_d, method: r.charge&.label || "Credit",
                                 invoice:, week: } }, status: :created
        end

        # PATCH /app/cca/bookings/:id/not_riding { not_riding: true|false } → booking
        def not_riding
          b = ::ConvoyApp::Cca::NotRiding.call(member: current_member, booking_id: params[:id], not_riding: params.require(:not_riding))
          render json: { data: { id: b.id, date: b.date, not_riding: b.not_riding } }
        end

        # PUT /app/cca/same_days { school_id, dependant_id, days: [2, 4] } → { dependant_id, on, days, text }; days [] = off
        def same_days
          render json: { data: ::ConvoyApp::Cca::SameDays.call(member: current_member, school_id: params[:school_id], dependant_id: params.require(:dependant_id),
                                                               days: params[:days]) }
        end

        private

        def require_billing!
          render_error(:forbidden, "Only the Billing Contact of your Family can pay for CCA rides", code: "billing_only") unless billing?
        end

        def payment_args
          { school_id: params[:school_id], picks: params[:picks], method: params[:method] }
        end
      end
    end
  end
end

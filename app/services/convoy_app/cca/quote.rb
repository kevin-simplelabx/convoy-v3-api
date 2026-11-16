# Convoy App › CCA Bus, what the picks come to before paying: rides × price, the Family's credit first, then the admin fee of
# the method picked on what is left. Checks the picks exactly as paying does (cut-off, days, seats), so the Pay button can
# only fail on a race. Writes nothing.
module ConvoyApp
  module Cca
    class Quote < ApplicationService
      def initialize(member:, school_id:, picks:, method: nil)
        @household = member.household
        @school_id = school_id
        @picks = picks
        @method = method
      end

      def call
        offer = Cca.offer!(@household, @school_id)
        Parents.within(offer.company) do
          q = CcaRides::Pay.new(offer.family, picks: Cca.picks(offer, @picks), today: Date.current).quote
          Cca::Quote.json(q, offer, Cca.methods(offer.school), @method)
        end
      end

      def self.json(q, offer, options, key)
        price = offer.setting.price
        option = options.find { it.key == key.to_s } || options.first
        fee = q.total.positive? ? option.fee_for(q.total) : 0.to_d
        rows = [ { k: "#{q.rides} #{q.rides == 1 ? 'ride' : 'rides'} × #{Cca.money(price)}", v: q.gross } ]
        rows << { k: "Credit", v: -q.credit } if q.credit.positive?
        rows << { k: "#{option.label} admin fee", v: fee } if fee.positive?
        { school_id: offer.school.id, rides: q.rides, price:, gross: q.gross, credit: q.credit, subtotal: q.total, late: q.late,
          method: q.total.positive? ? option.key : nil, admin_fee: fee, total: q.total + fee, rows:, book_with_credit: !q.total.positive?,
          methods: options.map { it.json(q.total) } }
      end
    end
  end
end

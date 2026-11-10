class OperatorPayBatchBlueprint < ApplicationBlueprint
  fields :number, :kind, :pay_date, :transfer_type, :bank_file_at, :created_at

  field(:status) { |b| b.status }
  field(:open) { |b| b.open? }
  field(:total) { |b| format("%.2f", b.total) }
  field(:paid) { |b| format("%.2f", b.paid) }
  field(:operators_count) { |b| b.batch_operators.size }
  # "Created by … on … | Bank file (FAST) by … on …"
  field(:created_by) { |b| b.created_by && { id: b.created_by.id, name: b.created_by.shown_name } }
  field(:bank_file_by) { |b| b.bank_file_by && { id: b.bank_file_by.id, name: b.bank_file_by.shown_name } }

  view :detail do
    field(:operators) do |b|
      b.batch_operators.sort_by { |x| x.operator.name }.map do |bo|
        pays = bo.notice_number ? { method: bo.pay_method, to: bo.pay_to, warn: false } : bo.operator.decorate.pays_by
        { id: bo.id, operator: { id: bo.operator.id, name: bo.operator.name }, pays_by: pays, notice_number: bo.notice_number, can_remove: b.open?,
          total: format("%.2f", bo.total), paid: format("%.2f", bo.paid), left: format("%.2f", bo.left), status: bo.status,
          lines: bo.lines.map { |l| l.slice(:id, :ref, :source, :description, :details, :item_on, :amount) },
          payments: bo.payments.map { |p| { id: p.id, paid_on: p.paid_on, amount: p.amount, method: p.method, reference: p.reference, by: p.recorded_by&.shown_name } } }
      end
    end
  end
end

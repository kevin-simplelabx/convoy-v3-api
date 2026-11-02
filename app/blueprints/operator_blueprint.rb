class OperatorBlueprint < ApplicationBlueprint
  fields :name, :kind, :uen, :contact_name, :phone, :email, :payment_method, :paynow_uen, :bank_id,
         :bank_code, :branch_code, :account_number, :account_name, :valid_until, :cost_per_trip, :cost_per_day

  # Managed Operators form and record: bank names, the number as sent, Pays By.
  view :detail do
    field(:bank_name) { |o| o.bank&.short_name }
    field(:branch_name) { |o| o.branch_name }
    field(:account_number_sent) { |o| o.account_number_sent }
    field(:pays_by) { |o| o.pays_by }
  end

  # Managed Operators list: also the Routes and vehicles columns.
  view :list do
    include_view :detail
    field(:routes_count) { |o, options| options[:routes]&.dig(o.id).to_i }
    field(:vehicles_count) { |o, options| options[:vehicles]&.dig(o.id).to_i }
  end
end

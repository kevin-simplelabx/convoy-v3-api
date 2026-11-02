# Vehicle Financials > edit form (Save): funding, purchase, loan terms, the lender's schedule file (or the document read
# of it: empty fields are filled from the reading and the instalments it shows as paid are marked). A schedule for
# another plate needs use_anyway.
module VehicleFinance
  class Save < ApplicationService
    FIELDS = %i[funding purchase_price down_payment bought_on lender account_number loan_amount rate tenure_months term_charge
                first_instalment monthly_instalment last_instalment first_due_on].freeze

    def initialize(vehicle:, params:, user:, document_read: nil, use_anyway: false)
      @vehicle = vehicle
      @params = params
      @user = user
      @read = document_read
      @use_anyway = use_anyway
    end

    def call
      raise Error, "Vehicle Financials are for own vehicles" unless @vehicle.own?

      fin = @vehicle.financial || @vehicle.build_financial(company_id: @vehicle.company_id)
      VehicleFinancial.transaction do
        fin.assign_attributes(@params.slice(*FIELDS, :schedule_file).merge(updated_by: @user))
        paid = apply_reading(fin) if @read
        fin.save!
        mark_paid(fin, paid) if paid
      end
      fin
    end

    private

    def apply_reading(fin)
      r = (@read.result || {}).deep_symbolize_keys
      if r[:plate].present? && r[:plate] != @vehicle.plate.delete(" ") && !@use_anyway
        raise Error, "This schedule is for #{r[:plate]}, not #{@vehicle.plate}. Use Anyway or Remove File first"
      end

      FIELDS.each { |k| fin[k] = r[k] if fin[k].blank? && r[k].present? }
      fin.funding = "loan"
      fin.document_read = @read
      fin.schedule_file = @read.file.file if fin.schedule_file.blank? && @read.file.present?
      Array(r[:paid])
    end

    def mark_paid(fin, paid)
      paid.each do |p|
        fin.payments.find_or_create_by!(instalment_no: p[:n]) { |x| x.assign_attributes(paid_on: p[:paid_on] || Date.current, recorded_by: @user) }
      end
    end
  end
end

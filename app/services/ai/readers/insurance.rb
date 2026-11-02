# Singapore motor insurance paper: policy schedule, Certificate of Insurance or premium debit note.
module Ai
  module Readers
    class Insurance < Base
      KINDS = %w[policy certificate invoice other].freeze
      POLICY_FIELDS = %i[insurer policy_number cover_type starts_on ends_on excess excess_third_party hire_purchase_company
                         agent holder premium gst total debit_note_number debit_note_date].freeze

      ask <<~TEXT
        This should be a Singapore motor insurance document for a bus or van: a policy schedule, a Certificate of Insurance,
        or a premium debit note / tax invoice (it may be a scanned image, read the text in it). Fill every key:
        is_insurance (true or false), kind (policy, certificate, invoice or other), plate (vehicle registration number, uppercase, no spaces),
        insurer (insurance company name, e.g. Income Insurance Limited), policy_number (policy or certificate number),
        cover_type (e.g. Comprehensive, Third Party Fire and Theft, Third Party Only), starts_on (effective date), ends_on (expiry date),
        chassis_number, excess (own damage excess, Section I), excess_third_party (third party excess, Section II),
        hire_purchase_company (hire purchase company or financier), agent (agency or intermediary), holder (policyholder name),
        premium (premium before GST), gst (GST amount), total (total payable), debit_note_number (debit note or invoice number),
        debit_note_date (debit note or invoice date). Amounts as plain numbers like 1234.50. Write every date as YYYY-MM-DD.
        Use an empty string for anything not shown. Do not guess.
      TEXT
      reply Ai::Schema.object(
        is_insurance: :boolean, kind: Ai::Schema.enum(*KINDS), plate: :string, insurer: :string, policy_number: :string,
        cover_type: :string, starts_on: :string, ends_on: :string, chassis_number: :string, excess: :string,
        excess_third_party: :string, hire_purchase_company: :string, agent: :string, holder: :string, premium: :string,
        gst: :string, total: :string, debit_note_number: :string, debit_note_date: :string
      )
      thinking :low

      def clean(r)
        raise ApplicationService::Error, "This does not look like an insurance document" if r[:is_insurance] == false

        {
          kind: KINDS.include?(r[:kind]) ? r[:kind] : "other", plate: plate(r[:plate]), insurer: str(r[:insurer]),
          policy_number: str(r[:policy_number]), cover_type: str(r[:cover_type]), starts_on: date(r[:starts_on]),
          ends_on: date(r[:ends_on]), chassis_number: str(r[:chassis_number])&.upcase, excess: number(r[:excess]),
          excess_third_party: number(r[:excess_third_party]), hire_purchase_company: str(r[:hire_purchase_company]),
          agent: str(r[:agent]), holder: str(r[:holder]), premium: number(r[:premium]), gst: number(r[:gst]),
          total: number(r[:total]), debit_note_number: str(r[:debit_note_number]), debit_note_date: date(r[:debit_note_date])
        }.compact
      end
    end
  end
end

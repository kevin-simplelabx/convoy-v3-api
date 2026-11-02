# Fuel Companies window saved at once: rows [{ id?, name, kind }] in order. A row with an id renames / retypes that
# company, one without adds it, one left out is deleted unless an entry uses it.
module FuelCompanies
  class Save < ApplicationService
    def initialize(rows:)
      @rows = Array(rows).map { |r| r.to_h.symbolize_keys.merge(name: r[:name].to_s.squish) }.reject { |r| r[:name].blank? && r[:id].blank? }
    end

    def call
      raise Error, "Give every company a name" if @rows.any? { |r| r[:name].blank? }
      raise Error, "Two companies have the same name" if @rows.map { |r| r[:name].downcase }.uniq.size < @rows.size

      FuelCompany.transaction do
        current = FuelCompany.all.index_by(&:id)
        keep = @rows.filter_map { |r| r[:id].presence&.to_i }
        gone = current.except(*keep).values
        used = FuelEntry.where(fuel_company_id: gone.map(&:id)).group(:fuel_company_id).count
        gone.each do |c|
          n = used[c.id].to_i
          raise Error, "#{c.name} is used by #{n} #{'entry'.pluralize(n)}, so it can't be deleted" if n.positive?

          c.destroy!
        end
        current.slice(*keep).each_value { |c| c.update_columns(name: "__#{c.id}") }
        @rows.each_with_index.map do |r, i|
          company = r[:id].present? ? current.fetch(r[:id].to_i) : FuelCompany.new
          company.update!(name: r[:name], kind: r[:kind].presence || company.kind, position: i)
          company
        end
      end
    end
  end
end

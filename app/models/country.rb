# A country a company can run in (config/presets/countries.yml): base map, weather and traffic sources, currency,
# timezone. Not a table: Convoy changes the list with a release.
Country = Data.define(:code, :name, :live, :timezone, :currency, :phone_prefix, :map, :weather, :traffic) do
  def self.all = @all ||= YAML.load_file(Rails.root.join("config/presets/countries.yml")).map { |h| new(**h.symbolize_keys) }.freeze
  def self.find(code) = all.find { |c| c.code == code.to_s.upcase }
  def self.codes = all.map(&:code)
  def self.live_codes = all.select(&:live).map(&:code)

  def sources = "Base map #{map}, weather from #{weather}, traffic from #{traffic}"
end

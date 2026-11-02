# Platform Message Terms for Fill from Message.
YAML.load_file(Rails.root.join("config/presets/message_terms.yml")).each do |t|
  MessageTerm.where("LOWER(term) = ?", t["term"].downcase).first_or_initialize.update!(term: t["term"], means: t["means"], kind: t["kind"])
end

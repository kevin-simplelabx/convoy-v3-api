# Singapore banks and branch codes (ACH Bank and Branch Code Guide), platform-wide. From db/seeds/files/sg_banks.json,
# exported from Convoy Project/sg-banks.js. UOB and Far Eastern Bank branches are found by the account's first 3 digits.
data = JSON.parse(File.read(Rails.root.join("db/seeds/files/sg_banks.json")))
data["banks"].each_with_index do |b, i|
  bank = Bank.find_or_initialize_by(key: b["key"])
  bank.update!(code: b["code"], name: b["name"], short_name: b["short_name"], branch_rule: b["branch_rule"], position: i)
  rows = b["branch_rule"] == "uob" ? data["uob_prefixes"].map { |prefix, (code, name)| [ code, name, prefix ] } : b["branches"].map { |code, name| [ code, name, nil ] }
  next if bank.branches.count == rows.size

  bank.branches.delete_all
  now = Time.current
  BankBranch.insert_all!(rows.map { |code, name, prefix| { bank_id: bank.id, code:, name:, account_prefix: prefix, created_at: now, updated_at: now } })
end

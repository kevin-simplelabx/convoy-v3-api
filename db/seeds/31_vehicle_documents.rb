# Insurance from the sample documents in uploads/: PC7475L (text PDF, details taken from it) and
# PC7939R (scanned PDF, file only, for Claude to read). Log card details for two own buses.
with_company("SD") do
  pc7475 = Vehicle.kept.find_by!(plate: "PC7475L")
  pc7475.update!(chassis_number: "JTFST22P800038072") if pc7475.chassis_number.blank?
  policy = pc7475.current_insurance_policy || pc7475.insurance_policies.create!(current: true)
  policy.update!(insurer: "Income Insurance Limited", policy_number: "5157592138-01", cover_type: "Third Party, Fire & Theft",
                 starts_on: "2026-06-27", ends_on: "2027-06-26", excess_third_party: 3000,
                 hire_purchase_company: "THINK ONE CREDIT PTE LTD", premium: 1525.67, gst: 137.31, total: 1662.98)
  if policy.documents.none?
    policy.documents.create!(file: SeedFiles.open("insurance", "PC7475L-insurance.pdf"), kind: "certificate", plate_on_document: "PC7475L")
  end

  pc7939 = Vehicle.kept.find_by!(plate: "PC7939R")
  scan_policy = pc7939.current_insurance_policy || pc7939.insurance_policies.create!(current: true)
  if scan_policy.documents.none?
    scan_policy.documents.create!(file: SeedFiles.open("insurance", "PC7939R-insurance-2026-2027.pdf"), kind: "policy")
  end

  {
    "PD3318K" => { chassis_number: "TRH223-0012345", engine_number: "1TR-7712345", registered_on: "2023-03-14",
                   coe_expires_on: "2033-03-13", road_tax_expires_on: Date.current + 20 },
    "PE1290S" => { chassis_number: "LZYTBTD61R1004521", engine_number: "YC6L310-50", registered_on: "2024-05-02",
                   coe_expires_on: "2041-05-01", road_tax_expires_on: Date.current + 160 }
  }.each do |plate, details|
    vehicle = Vehicle.kept.find_by!(plate:)
    vehicle.update!(details) if vehicle.chassis_number.blank?
  end
end

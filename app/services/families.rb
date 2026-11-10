# School Bus families: search, the riders a family could take (parent matches first), and the CSV in / out.
module Families
  COLUMNS = %w[family_id family_name guardian_name relationship phone email student_id student_name].freeze

  module_function

  # Families of a school matching q: name, code, a guardian's name / phone / email, a rider's ID or name; 3+ digits also
  # match phone numbers by digits.
  def search(scope, school, q)
    q = q.to_s.strip
    return scope if q.empty?

    like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
    digits = q.gsub(/\D/, "")
    g = FamilyGuardian.where("CONCAT_WS(' ', first_name, last_name, email, phone) ILIKE ?", like)
    g = g.or(FamilyGuardian.where("regexp_replace(COALESCE(phone, ''), '\\D', '', 'g') LIKE ?", "%#{digits}%")) if digits.length >= 3
    names = SchoolRider.where(school:).where("name ILIKE :q OR rid ILIKE :q", q: like).select(:rid)
    scope.where("families.name ILIKE :q OR families.code ILIKE :q", q: like)
         .or(scope.where(id: g.select(:family_id)))
         .or(scope.where(id: FamilyRider.where(school:).where("rid ILIKE ?", like).select(:family_id)))
         .or(scope.where(id: FamilyRider.where(school:, rid: names).select(:family_id)))
  end

  # Link Existing Rider: the riders of the school who are in no family (HTML `pool`), parent matches first (the rider's
  # parent name, or the last 8 digits of the parent contact, matches a guardian), then by name; searched by q. A rider
  # sharing a guardian's last name is flagged `last_name` but is not ranked.
  def candidates(family, school, q: nil, date: Date.current)
    guardians = family.guardians.to_a
    names = guardians.map { it.name.downcase }.to_set
    tails = guardians.filter_map(&:phone_tail).to_set
    surnames = guardians.filter_map { it.last_name&.downcase }.to_set
    riders = SchoolRider.of_school_on(school, date).where.not(rid: FamilyRider.where(school:).select(:rid)).order(:name)
    riders = riders.search(q).or(riders.where("parent_name ILIKE ?", "%#{q}%")) if q.present?
    riders.to_a.map do |r|
      parent = names.include?(r.parent_name.to_s.downcase) || tails.include?(r.parent_contact.to_s.gsub(/\D/, "")[-8..])
      same = surnames.any? { |s| r.name.downcase.split.include?(s) }
      { rid: r.rid, name: r.name, grade: r.grade, parent_name: r.parent_name, address: r.address, postal: r.postal,
        match: parent ? "parent" : (same ? "last_name" : nil) }
    end.sort_by { [ it[:match] == "parent" ? 0 : 1, it[:name].to_s.downcase ] }.first(200)
  end

  def link(family, school, rids)
    FamilyRider.transaction do
      rids.each do |rid|
        FamilyRider.where(school:, rid:).where.not(family:).delete_all
        FamilyRider.find_or_create_by!(family:, school:, rid:)
      end
    end
  end

  def export(school)
    CSV.generate do |csv|
      csv << COLUMNS
      names = SchoolRider.where(school:).pluck(:rid, :name).to_h
      school.families.includes(:guardians, :family_riders).order(:code).each do |f|
        kids = f.family_riders.select { it.school_id == school.id }
        rows = [ f.guardians.size, kids.size, 1 ].max
        rows.times do |i|
          g = f.guardians[i]
          k = kids[i]
          csv << [ f.code, f.name, g&.name, g&.relationship, g&.phone, g&.email, k&.rid, k && names[k.rid] ]
        end
      end
    end
  end
end

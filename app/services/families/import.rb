# Families CSV import (as Convoy OS): rows matched to a family by family_id, else family_name, else a guardian's phone;
# rows with none are skipped. An unknown family_id makes a family; a different name renames it (warned). Guardians are
# matched by name and updated; a student is linked (and leaves any other family at the school; an unknown student ID is
# linked with a warning). Families left with nobody are deleted. Returns counts and up to 30 warnings.
module Families
  class Import < ApplicationService
    def initialize(school, text)
      @school = school
      @text = text.to_s.delete_prefix("﻿")
    end

    def call
      rows = CSV.parse(@text, headers: true, header_converters: ->(h) { h.to_s.strip.downcase.tr(" ", "_") })
      raise Error, "The file has no family_id, family_name or phone column" unless rows.headers.intersect?(%w[family_id family_name phone])

      @out = { families_added: 0, families_renamed: 0, guardians_added: 0, guardians_updated: 0, riders_linked: 0, skipped: 0, families_deleted: 0, warnings: [] }
      known = SchoolRider.where(school: @school).pluck(:rid).to_set
      Family.transaction do
        rows.each.with_index(2) do |row, line|
          fam = find_family(row, line) or next
          guardian(fam, row, line)
          rider(fam, row, line, known)
          fam.save!
        end
        empty = @school.families.left_joins(:family_riders, :guardians).where(family_riders: { id: nil }, family_guardians: { id: nil })
        @out[:families_deleted] = empty.count
        empty.destroy_all
      end
      @out[:warnings] = @out[:warnings].first(30)
      @out
    end

    private

    def find_family(row, line)
      code = row["family_id"].to_s.strip.upcase
      name = row["family_name"].to_s.strip
      phone = row["phone"].to_s.gsub(/\D/, "")[-8..]
      fam = lookup(code, name, phone)
      if fam.nil? && code.blank? && name.blank? && phone.blank?
        @out[:skipped] += 1
        return nil
      end
      if fam.nil?
        @out[:families_added] += 1
        fam = @school.families.new(code: code.presence || Family.next_code, name: name.presence || "New Family", name_mode: name.present? ? "custom" : "auto")
        fam.save!
      elsif name.present? && fam.name != name
        @out[:warnings] << "Line #{line}: #{fam.code} renamed from #{fam.name} to #{name}"
        @out[:families_renamed] += 1
        fam.assign_attributes(name:, name_mode: "custom")
      end
      fam
    end

    def lookup(code, name, phone)
      return Family.find_by(code:) if code.present?
      return @school.families.find_by("LOWER(name) = ?", name.downcase) if name.present?
      return nil if phone.blank?

      Family.joins(:guardians).find_by("RIGHT(regexp_replace(family_guardians.phone, '\\D', '', 'g'), 8) = ?", phone)
    end

    def guardian(fam, row, line)
      name = row["guardian_name"].to_s.strip
      return if name.empty?

      email = row["email"].to_s.strip
      @out[:warnings] << "Line #{line}: #{email} doesn't look like an email" if email.present? && !email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      g = fam.guardians.find { it.name.casecmp?(name) }
      first, *rest = name.split
      attrs = { relationship: FamilyGuardian::RELATIONSHIPS.find { it.casecmp?(row["relationship"].to_s.strip) } || "Parent",
                phone: row["phone"].to_s.strip.presence, email: email.presence&.then { it.match?(/@/) ? it : nil } }
      if g
        g.update!(attrs.compact)
        @out[:guardians_updated] += 1
      else
        fam.guardians.create!(attrs.merge(first_name: first, last_name: rest.join(" ").presence, name_order: "first", position: fam.guardians.size))
        @out[:guardians_added] += 1
      end
    end

    def rider(fam, row, line, known)
      rid = row["student_id"].to_s.strip
      return if rid.empty?

      @out[:warnings] << "Line #{line}: student #{rid} is not on the rider list" unless known.include?(rid)
      Families.link(fam, @school, [ rid ])
      @out[:riders_linked] += 1
    end
  end
end

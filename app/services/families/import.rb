# Families CSV import (port of famImport): a row joins the family of its family_id (an unknown one makes a family), else
# the family its family_name or, without one, its phone makes within the file — never a family already in the company.
# A different name renames the family (warned). Guardians are matched by name and updated, a wrong phone or email is
# warned and left out, the relationship defaults to Guardian; a family with no name is named after its first guardian,
# else its code. A student is linked (and leaves any other family at the
# school; an unknown student ID is linked with a warning). Only a family that lost riders to this import and is left with
# nobody is deleted; one left with guardians only is warned. Returns counts and up to 30 warnings.
module Families
  class Import < ApplicationService
    EMAIL = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

    def initialize(school, text)
      @school = school
      @text = text.to_s.delete_prefix("﻿")
    end

    def call
      rows = CSV.parse(@text, headers: true, header_converters: ->(h) { h.to_s.strip.downcase.tr(" ", "_") })
      raise Error, "The file has no family_id, family_name or phone column" unless rows.headers.intersect?(%w[family_id family_name phone])

      @out = { families_added: 0, families_renamed: 0, guardians_added: 0, guardians_updated: 0, riders_linked: 0, skipped: 0, families_deleted: 0, warnings: [] }
      @known = SchoolRider.where(school: @school).pluck(:rid).to_set
      @grouped = {}
      @created = Set.new
      @renamed = Set.new
      @touched = Set.new
      @lost = Set.new
      @unnamed = Set.new
      Family.transaction do
        rows.each.with_index(2) do |row, line|
          fam = find_family(row, line) or next
          @touched << fam.id
          guardian(fam, row, line)
          rider(fam, row, line)
          fam.save!
        end
        tidy
      end
      @out[:warnings] = @out[:warnings].first(30)
      @out
    end

    private

    def find_family(row, line)
      code = row["family_id"].to_s.strip.upcase
      name = row["family_name"].to_s.strip
      phone = row["phone"].to_s.gsub(/\D/, "")
      fam = code.present? ? Family.find_by(code:) || build(code, name) : grouped(name, phone, line)
      return unless fam

      @unnamed.delete(fam.id) if name.present?
      if name.present? && fam.name != name
        if @created.include?(fam.id) || @renamed.include?(fam.id)
          fam.assign_attributes(name:, name_mode: "custom")
        else
          @out[:warnings] << "Line #{line}: #{fam.code} renamed from #{fam.name} to #{name}. Check the family_id is right"
          @out[:families_renamed] += 1
          @renamed << fam.id
          fam.assign_attributes(name:, name_mode: "custom")
        end
      end
      fam
    end

    # A row with no family_id: the family made in this file for the same name, else for the same phone.
    def grouped(name, phone, line)
      key = name.present? ? "n:#{name.downcase}" : (phone.present? ? "p:#{phone}" : nil)
      unless key
        @out[:skipped] += 1
        @out[:warnings] << "Line #{line}: no family_id, family_name or phone, skipped"
        return
      end
      @grouped[key] ||= build(nil, name)
    end

    def build(code, name)
      fam = @school.families.create!(code: code.presence || Family.next_code(@school), name: name.presence || "New Family", name_mode: "custom")
      @out[:families_added] += 1
      @created << fam.id
      @unnamed << fam.id if name.blank?
      fam
    end

    def guardian(fam, row, line)
      name = row["guardian_name"].to_s.strip
      return if name.empty?

      phone = row["phone"].to_s.strip
      email = row["email"].to_s.strip
      if phone.present? && !phone.match?(FamilyGuardian::PHONE)
        @out[:warnings] << "Line #{line}: #{phone} doesn't look like a phone number, left out"
        phone = ""
      end
      if email.present? && !email.match?(EMAIL)
        @out[:warnings] << "Line #{line}: #{email} doesn't look like an email, left out"
        email = ""
      end
      g = fam.guardians.find { it.name.casecmp?(name) }
      first, *rest = name.split
      relationship = FamilyGuardian::RELATIONSHIPS.find { it.casecmp?(row["relationship"].to_s.strip) }
      attrs = { relationship:, phone: phone.presence, email: email.presence }.compact
      if g
        g.update!(attrs)
        @out[:guardians_updated] += 1
      else
        fam.guardians.create!({ relationship: "Guardian", first_name: first, last_name: rest.join(" ").presence, name_order: "first", position: fam.guardians.size }.merge(attrs))
        @out[:guardians_added] += 1
      end
    end

    def rider(fam, row, line)
      rid = row["student_id"].to_s.strip
      return if rid.empty?

      @out[:warnings] << "Line #{line}: student #{rid} is not on the rider list" unless @known.include?(rid)
      @lost.merge(FamilyRider.where(school: @school, rid:).where.not(family: fam).pluck(:family_id))
      Families.link(fam, @school, [ rid ])
      @out[:riders_linked] += 1
    end

    # Families that lost riders to the file and were not in it: gone when empty; still with guardians, warned.
    def tidy
      Family.where(id: @unnamed.to_a).includes(:guardians).each { it.update!(name: it.guardians.first&.name || it.code) }
      left = Family.where(id: @lost - @touched).includes(:guardians, :family_riders).select { it.family_riders.empty? }
      gone, orphans = left.partition { it.guardians.empty? }
      Family.where(id: gone.map(&:id)).destroy_all
      @out[:families_deleted] = gone.size
      orphans += Family.where(id: @lost & @touched).includes(:guardians, :family_riders).select { it.family_riders.empty? && it.guardians.any? }
      @out[:warnings].unshift("#{orphans.size} families lost all their riders but still have guardians. Review or delete them") if orphans.any?
    end
  end
end

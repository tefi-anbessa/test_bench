# app/services/import/tags.rb
module Import
  # Tag plugin for the import framework - see Import::Base for what's
  # generic. Resolved by Import::Base.registered("tags") via naming
  # convention - see Import::Base.
  class Tags < Base
    FULL_TAG_PATTERN = /\A([A-Za-z]+)(\d+)([A-Za-z]*)\z/

    def model_class
      Tag
    end

    def permitted_attributes
      Tag::IMPORTABLE_ATTRIBUTES
    end

    def column_definitions
      definitions = [
        ColumnDefinition.new(key: :full_tag, label: "Tag Number", aliases: ["Instrument Tag", "Tag No"]),
        ColumnDefinition.new(key: :prefix, label: "Prefix"),
        ColumnDefinition.new(key: :serial, label: "Serial", coercer: ->(value) { value.to_s.strip.presence&.to_i }),
        ColumnDefinition.new(key: :suffix, label: "Suffix"),
        ColumnDefinition.new(key: :service, label: "Service"),
        ColumnDefinition.new(key: :location, label: "Location"),
        ColumnDefinition.new(key: :notes, label: "Notes"),
        ColumnDefinition.new(key: :stage, label: "Stage", coercer: ->(value) { value.to_s.strip.presence&.to_i }),
        ColumnDefinition.new(key: :tagable_type, label: "Type", aliases: ["Tagable Type"]),
        ColumnDefinition.new(key: :parent, label: "Parent Tag")
      ]
      # Only a project-wide import (no discipline fixed via the URL, and none
      # chosen for the whole batch) needs a discipline column to map at all.
      definitions << ColumnDefinition.new(key: :discipline, label: "Discipline", aliases: ["Disc"]) if context[:discipline].nil?
      definitions
    end

    # A combined "Tag Number" column (e.g. "PT0001A") decomposes the same way
    # full_tag itself is composed (letters / digits / trailing letters) -
    # mutually exclusive with mapping prefix/serial/suffix directly, and
    # doesn't override them if both were somehow mapped.
    def post_process_attributes(attrs)
      return attrs unless attrs.key?(:full_tag)

      full_tag = attrs.delete(:full_tag)
      match = full_tag.to_s.strip.match(FULL_TAG_PATTERN)
      if match
        attrs[:prefix] ||= match[1].upcase
        attrs[:serial] ||= match[2].to_i
        attrs[:suffix] ||= match[3].presence
      end
      attrs
    end

    def resolve_foreign_keys(row, context:)
      resolve_discipline!(row, context)
      resolve_tagable_type!(row)
    end

    def deferred_reference_attribute
      :parent_id
    end

    # Matches Tag#long_label ("#{discipline.code}#{separator}#{full_tag}") -
    # the same format shown throughout the UI, and the shape a future
    # exporter would print for a parent reference.
    def natural_key_for(row)
      discipline = discipline_cache[row.attributes[:discipline_id]]
      return nil unless discipline
      full_tag = full_tag_for(row.attributes)
      return nil unless full_tag
      "#{discipline.code}#{Constants.tag.separator}#{full_tag}"
    end

    # Accepts either the qualified form ("E-PT0001A" - valid across
    # disciplines within one project, see Tag#prevent_cross_project_reference
    # which only checks project) or a bare full_tag. A bare reference is
    # qualified here (using the *referencing* row's own resolved discipline)
    # before being handed to Import::DeferredReferences, so its in-batch
    # index - built from natural_key_for, which is always qualified - can
    # actually match it; DeferredReferences itself has no notion of
    # "same discipline as the referencing row" to do this qualification with.
    def reference_for(row)
      raw = row.attributes[:parent]
      return nil if raw.blank?

      value = raw.to_s.strip
      return value if value.include?(Constants.tag.separator)

      discipline = discipline_cache[row.attributes[:discipline_id]]
      return value unless discipline
      "#{discipline.code}#{Constants.tag.separator}#{value}"
    end

    # By the time this runs, raw_reference is always already qualified (see
    # #reference_for above).
    def resolve_persisted_reference(raw_reference, _row)
      code, full_tag = raw_reference.to_s.strip.split(Constants.tag.separator, 2)
      return nil if full_tag.blank?

      Tag.joins(discipline: :project)
        .where(projects: { id: context[:project].id }, disciplines: { code: code })
        .find_by(full_tag: full_tag)
    end

    def authorize!(rows, pundit_user:)
      discipline_ids = rows.filter_map { |row| row.attributes[:discipline_id] }.uniq
      discipline_ids.each do |discipline_id|
        discipline = discipline_cache[discipline_id]
        next unless discipline
        unless TagPolicy.new(pundit_user, discipline.tags.build).create?
          raise Pundit::NotAuthorizedError, "not allowed to import tags into #{discipline.long_label}"
        end
      end
    end

    private

    def resolve_discipline!(row, context)
      if context[:discipline]
        row.attributes.delete(:discipline)
        row.attributes[:discipline_id] = context[:discipline].id
        return
      end

      value = row.attributes.delete(:discipline)
      if value.blank?
        row.add_resolution_error("No discipline could be determined for this row - map a discipline column, or choose a single discipline for this import")
        return
      end

      discipline = find_discipline(context[:project], value)
      if discipline
        row.attributes[:discipline_id] = discipline.id
        discipline_cache[discipline.id] = discipline
      else
        row.add_resolution_error("Discipline '#{value}' not found in this project")
      end
    end

    def resolve_tagable_type!(row)
      value = row.attributes[:tagable_type]
      return if value.blank?

      matched = Tag.safe_tagable_types.find do |type|
        type.casecmp?(value.to_s.strip) || type.demodulize.casecmp?(value.to_s.strip)
      end

      if matched
        row.attributes[:tagable_type] = matched
      else
        row.add_resolution_error("Unknown type '#{value}' - expected one of #{Tag.safe_tagable_types.map(&:demodulize).join(', ')}")
      end
    end

    def find_discipline(project, value)
      code_or_name = value.to_s.strip
      return nil if code_or_name.blank?
      project.disciplines.find_by(code: code_or_name) || project.disciplines.find_by(name: code_or_name)
    end

    def full_tag_for(attrs)
      return nil unless attrs[:prefix].present? && attrs[:serial].present?
      padded_serial = attrs[:serial].to_s.rjust(Constants.tag.serial_digits, "0")
      "#{attrs[:prefix]}#{padded_serial}#{attrs[:suffix]}"
    end

    def discipline_cache
      @discipline_cache ||= {}.tap do |cache|
        cache[context[:discipline].id] = context[:discipline] if context[:discipline]
      end
    end
  end
end

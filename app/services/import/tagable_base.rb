# app/services/import/tagable_base.rb
module Import
  # Abstract superclass for a tagable model's import plugin (see
  # Import::Base for the wider framework this builds on). A tagable row
  # never creates a Tag - it always attaches to one that already exists,
  # persisted, unassigned (tagable_id nil), from an earlier Import::Tags run
  # that left it deliberately orphaned with tagable_type set. That's the
  # same two-step workflow the manual UI already supports
  # (TagablesController#create's "attach to an existing tag" path), just
  # done in bulk - see the natural-key resolution below.
  #
  # Discipline-scoped only (no project-wide variant): TagablesController has
  # no project-wide entry point at all, only discipline_tagables_path, so
  # context[:discipline] is always present here. The qualified
  # "code<separator>full_tag" form is still parsed (mirrors Import::Tags'
  # own parent-reference resolution) in case that ever changes, but nothing
  # in the app builds a UI for it today.
  class TagableBase < Base
    # Optional Tag-level fields a tagable-detail import can also set on the
    # Tag it resolves - lets one sheet mix tag-register info (Service,
    # Stage, ...) with model-specific columns (Motor Type, ...) instead of
    # requiring a separate Import::Tags pass first for every field. Prefixed
    # (tag_*) to avoid colliding with a same-named column on the tagable
    # itself (e.g. every tagable has its own "notes" too) - see
    # #tag_attribute_updates, where they're mapped back to the Tag's real
    # attribute names. Only applied when actually mapped and non-blank -
    # never overwrites an existing Tag value with a blank cell.
    TAG_ATTRIBUTE_KEYS = { tag_service: :service, tag_stage: :stage, tag_location: :location, tag_notes: :notes }.freeze

    def column_definitions
      [
        ColumnDefinition.new(key: :full_tag, label: "Tag", aliases: ["Instrument Tag", "Tag No", "Tag Number"]),
        ColumnDefinition.new(key: :tag_service, label: "Service"),
        ColumnDefinition.new(key: :tag_stage, label: "Stage", coercer: ->(value) { value.to_s.strip.presence&.to_i }),
        ColumnDefinition.new(key: :tag_location, label: "Location"),
        ColumnDefinition.new(key: :tag_notes, label: "Tag Notes")
      ] + own_column_definitions
    end

    # === Subclass interface - required (mirrors Import::Base's own) ===

    def own_column_definitions
      raise NotImplementedError, "#{self.class} must implement #own_column_definitions"
    end

    def resolve_foreign_keys(row, context:)
      raw = row.attributes.delete(:full_tag)
      if raw.blank?
        row.add_resolution_error("No tag reference given for this row - map a Tag column")
        return
      end

      tag = find_tag(context, raw)
      if tag.nil?
        if batch.create_missing_tags?
          build_new_tag_from_natural_key(row, raw)
        else
          row.add_resolution_error("Tag '#{raw}' not found")
        end
      elsif tag.tagable_id.present?
        row.add_resolution_error("Tag '#{raw}' is already assigned to another #{tag.tagable_type}")
      elsif tag.tagable_type != model_class.name
        row.add_resolution_error("Tag '#{raw}' is registered as #{tag.tagable_type}, not #{model_class.name}")
      else
        # Reuses the same per-discipline authorize! hoisting Import::Tags
        # already does - discipline_id here isn't a column on the tagable
        # itself (there is none), just a signal for that hoisting.
        row.attributes[:discipline_id] = tag.discipline_id
        resolved_tags[row] = tag
      end
    end

    # Uses create? specifically (not update?) because
    # TagablesController#create's own "attach to an existing unassigned
    # tag" path already authorizes via @tag with create? too - this keeps
    # the bulk path's authorization identical to the manual UI path it's
    # replacing, not a second story.
    def authorize!(rows, pundit_user:)
      discipline_ids = rows.filter_map { |row| row.attributes[:discipline_id] }.uniq
      discipline_ids.each do |discipline_id|
        discipline = discipline_cache[discipline_id]
        next unless discipline
        unless TagPolicy.new(pundit_user, discipline.tags.build).create?
          raise Pundit::NotAuthorizedError, "not allowed to import #{model_class.model_name.human(count: 2).downcase} into #{discipline.long_label}"
        end
      end
    end

    # Re-verifies the resolved tag is *still* unassigned and still the
    # right tagable_type before linking - a real race this feature
    # introduces that no existing importer has: dry-run and commit can be
    # arbitrarily far apart in time (the user reviews, walks away), during
    # which someone could grab the same tag via the ordinary manual UI.
    # Any failure here aborts the whole commit (see Import::Committer).
    def after_commit_row(row)
      tag = resolved_tags[row]
      return unless tag

      if tag.persisted?
        tag.lock!
        if tag.tagable_id.present? || tag.tagable_type != model_class.name
          raise "Tag #{tag.long_label} is no longer available to import into"
        end
        tag.update!(tag_attribute_updates(row).merge(tagable: row.record))
      else
        # Create path (see #build_new_tag_from_natural_key) - row.record is
        # already saved by this point in Committer's loop, so the new Tag's
        # tagable_id is known without needing Rails' autosave-association
        # cascade. A uniqueness race (another request creating the identical
        # tag between dry-run and commit) surfaces as a plain
        # ActiveRecord::RecordInvalid/RecordNotUnique here, already caught
        # generically by Import::Committer's own rescue.
        tag.tagable = row.record
        tag.save!
      end
    end

    def supports_tag_creation? = true

    # Every tagable shares one controller/route (discipline_tagables_path),
    # not a per-model one - see Import::Base#index_path, which this
    # overrides.
    def index_path(batch, url_helpers)
      url_helpers.discipline_tagables_path(batch.discipline, tagable_type: model_class.name)
    end

    private

    # Only reached when batch.create_missing_tags? and no existing tag
    # matched the natural key - builds an unsaved Tag from it (never
    # persisted here; see #after_commit_row for the actual save). The
    # qualified "code<separator>full_tag" cross-discipline form isn't
    # supported for creation (FULL_TAG_PATTERN can't match a string
    # containing the separator) - it falls through to the "not a valid tag
    # format" resolution error below, a documented, tested limitation rather
    # than a silent wrong-discipline creation.
    def build_new_tag_from_natural_key(row, raw)
      match = raw.to_s.strip.match(Tags::FULL_TAG_PATTERN)
      unless match
        row.add_resolution_error("Tag '#{raw}' not found, and isn't a valid tag format to create")
        return
      end

      prefix, serial, suffix = match[1].upcase, match[2].to_i, match[3].presence
      discipline = context[:discipline]
      key = [discipline.id, prefix, serial, suffix]
      if new_tag_keys.include?(key)
        row.add_resolution_error("Tag '#{raw}' is referenced by more than one row in this file")
        return
      end
      new_tag_keys << key

      tag = Tag.new(discipline: discipline, prefix: prefix, serial: serial, suffix: suffix,
        tagable_type: model_class.name, **tag_attribute_updates(row))
      unless tag.valid?
        row.add_resolution_error("Could not create tag '#{raw}': #{tag.errors.full_messages.join(", ")}")
        return
      end

      row.attributes[:discipline_id] = discipline.id
      resolved_tags[row] = tag
    end

    def new_tag_keys
      @new_tag_keys ||= Set.new
    end

    def tag_attribute_updates(row)
      TAG_ATTRIBUTE_KEYS.each_with_object({}) do |(row_key, tag_attr), updates|
        value = row.attributes[row_key]
        updates[tag_attr] = value if value.present?
      end
    end

    def resolved_tags
      @resolved_tags ||= {}
    end

    def discipline_cache
      @discipline_cache ||= {}.tap do |cache|
        cache[context[:discipline].id] = context[:discipline] if context[:discipline]
      end
    end

    def find_tag(context, raw)
      value = raw.to_s.strip
      return nil if value.blank?

      if value.include?(Constants.tag.separator)
        code, full_tag = value.split(Constants.tag.separator, 2)
        tag = Tag.joins(discipline: :project)
          .where(projects: { id: context[:project].id }, disciplines: { code: code })
          .find_by(full_tag: full_tag)
        discipline_cache[tag.discipline_id] ||= tag.discipline if tag
        tag
      else
        context[:discipline]&.tags&.find_by(full_tag: value)
      end
    end
  end
end

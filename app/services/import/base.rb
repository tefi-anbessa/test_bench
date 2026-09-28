# app/services/import/base.rb
module Import
  # Abstract superclass for one model's spreadsheet-import plugin. A subclass
  # (see Import::Tags) declares what's model-specific; this class provides
  # everything reusable: spreadsheet reading (any format, via
  # Import::SpreadsheetReader), column-mapping suggestion, dry-run row
  # building/validation, and the deferred-reference resolution mechanics
  # (via Import::DeferredReferences) for a self-referential/forward-reference
  # column, if the subclass has one.
  #
  # Registration: resolved by convention - key "tags" -> Import::Tags - not
  # an explicit self-registering hash. That was the first design here, but
  # it depended on the subclass file already having been autoloaded as a
  # side effect of something else referencing it directly; outside of CI,
  # config.eager_load is false (see config/environments/test.rb), so Zeitwerk
  # only loads a file the first time its constant is actually referenced -
  # and Import::Base.registered("tags") alone never does that. Confirmed the
  # hard way, via a controller test failing in isolation.
  class Base
    class << self
      def registered(key)
        "Import::#{key.to_s.camelize}".safe_constantize.tap do |klass|
          raise ArgumentError, "Unknown importer key: #{key.inspect}" unless klass&.< Import::Base
        end
      end
    end

    attr_reader :batch

    def initialize(batch)
      @batch = batch
    end

    # Passed to #resolve_foreign_keys and available to subclasses generally.
    # discipline is batch.discipline - present for a discipline-scoped import
    # *and* for a project-wide import where the user chose one discipline for
    # the whole file; nil only when a discipline column was mapped instead,
    # meaning each row resolves its own.
    def context
      { project: batch.project, discipline: batch.discipline, user: batch.user }
    end

    # === Subclass interface - required ===

    def model_class
      raise NotImplementedError, "#{self.class} must implement #model_class"
    end

    def column_definitions
      raise NotImplementedError, "#{self.class} must implement #column_definitions"
    end

    def permitted_attributes
      raise NotImplementedError, "#{self.class} must implement #permitted_attributes"
    end

    # Mutates row.attributes to resolve any foreign keys (e.g. discipline_id)
    # from the coerced values already present, and/or calls
    # row.add_resolution_error for anything that can't be resolved. Does not
    # handle deferred/self-referential references (e.g. parent) - that's
    # handled generically below via #natural_key_for/#reference_for/
    # #resolve_persisted_reference.
    def resolve_foreign_keys(row, context:)
      raise NotImplementedError, "#{self.class} must implement #resolve_foreign_keys"
    end

    # Raises Pundit::NotAuthorizedError if pundit_user (the controller's own
    # ApplicationPolicy::UserContext, from #pundit_user - not re-derived here)
    # can't import into every discipline referenced across these rows.
    # Checked once per distinct discipline, not per row.
    def authorize!(rows, pundit_user:)
      raise NotImplementedError, "#{self.class} must implement #authorize!"
    end

    # === Subclass interface - optional (default: no deferred reference) ===

    def deferred_reference_attribute = nil
    def natural_key_for(row) = nil
    def reference_for(row) = nil
    def resolve_persisted_reference(raw_reference, row) = nil

    # Override for any last, importer-specific attribute transformation
    # before foreign-key resolution - e.g. Tag decomposing a combined
    # "Tag Number" column into prefix/serial/suffix. Default: no-op.
    def post_process_attributes(attrs) = attrs

    # Called by Import::Committer immediately after a row's own record is
    # saved, inside the same transaction - for anything an importer needs to
    # do to an already-persisted, non-batch record as a result (e.g. a
    # tagable importer linking itself onto the existing Tag it resolved -
    # see Import::TagableBase). Any exception here aborts the whole commit.
    # Default: nothing to do.
    def after_commit_row(row) = nil

    # Whether this importer supports creating a new record (e.g. a Tag) as
    # part of resolving a row's foreign key, when nothing existing is found -
    # governs whether the mapping page offers an opt-in "create missing"
    # checkbox at all. Default: no such capability. See Import::TagableBase.
    def supports_tag_creation? = false

    # The path to redirect to once a batch is finished with (imported or
    # aborted) - default matches every plain discipline-resource importer's
    # own route convention (discipline_<route_key>_path/
    # project_<route_key>_path). url_helpers is the calling controller
    # itself (already has all its own route helpers) - not re-derived here,
    # since a route helper isn't available as a plain method outside a
    # controller/view context. Override when a model doesn't have its own
    # such route - e.g. every tagable shares one controller/route
    # (discipline_tagables_path) instead of a per-model one.
    def index_path(batch, url_helpers)
      route_key = model_class.model_name.route_key
      if batch.discipline.present?
        url_helpers.send("discipline_#{route_key}_path", batch.discipline)
      else
        url_helpers.send("project_#{route_key}_path", batch.project)
      end
    end

    # === Provided ===

    def reader
      @reader ||= SpreadsheetReader.new(batch_file_path, original_filename: batch.original_filename, sheet: batch.sheet_name)
    end

    def headers
      reader.headers
    end

    def sheet_names
      reader.sheet_names
    end

    def column_mapper(preset_mapping: {})
      ColumnMapper.new(column_definitions, headers: headers, preset_mapping: preset_mapping)
    end

    # The full dry-run pipeline: read -> coerce -> resolve foreign keys ->
    # authorize -> resolve deferred/self-referential references -> build
    # (unsaved) records -> validate. Always run fresh rather than cached (see
    # Import::Batch) - cheap at the row counts this is designed for, and
    # avoids staleness between mapping, review, and commit.
    #
    # Authorization runs as soon as every row's discipline is known, before
    # the (more revealing) record-building/validation step - an import
    # touching even one discipline pundit_user can't create tags in raises
    # immediately, rather than quietly validating and previewing rows the
    # user was never authorized to see.
    def dry_run_rows(pundit_user:)
      rows = build_rows
      rows.each { |row| resolve_foreign_keys(row, context: context) }
      authorize!(rows, pundit_user: pundit_user)
      resolve_deferred_references!(rows)
      rows.each { |row| build_and_validate_record!(row) }
      rows
    end

    private

    def batch_file_path
      batch_tempfile.path
    end

    # file_data lives in Postgres (see Import::Batch), not on local disk -
    # write it to a tempfile so SpreadsheetReader (and roo underneath it) can
    # open it as a normal file path. Kept as an instance variable
    # deliberately, not just its #path: a Tempfile unlinks its underlying
    # file when the Tempfile object itself is garbage-collected, regardless
    # of whether some other object still holds its path string - confirmed
    # directly (GC.start after discarding the Tempfile reference reliably
    # deletes the file). Holding the object here keeps it alive exactly as
    # long as this importer instance is.
    def batch_tempfile
      @batch_tempfile ||= Tempfile.new(["import_batch_", File.extname(batch.original_filename)], binmode: true).tap do |tempfile|
        tempfile.write(batch.file_data)
        tempfile.flush
      end
    end

    def build_rows
      definitions_by_key = column_definitions.index_by(&:key)

      reader.rows.each_with_index.map do |raw_row, index|
        row = Row.new(row_number: index + 2, raw: raw_row) # +2: 1-indexed, plus the header row itself
        row.attributes = post_process_attributes(build_attributes(raw_row, definitions_by_key))
        row
      end
    end

    def build_attributes(raw_row, definitions_by_key)
      batch.column_mapping.each_with_object({}) do |(header, key), attrs|
        next if key.blank?
        definition = definitions_by_key[key.to_sym]
        next unless definition
        attrs[definition.key] = definition.coerce(raw_row[header])
      end
    end

    def resolve_deferred_references!(rows)
      return unless deferred_reference_attribute

      results = DeferredReferences.new(
        rows: rows,
        natural_key_for: method(:natural_key_for),
        reference_for: method(:reference_for),
        resolve_persisted: method(:resolve_persisted_reference)
      ).resolve

      results.each do |row, result|
        if result[:error]
          row.add_resolution_error(result[:error])
        elsif result[:persisted]
          row.attributes[deferred_reference_attribute] = result[:persisted].id
        elsif result[:in_batch]
          row.deferred_reference_row = result[:in_batch]
        end
      end
    end

    def build_and_validate_record!(row)
      return if row.resolution_errors.any? # see Import::Row - no point layering generic validation errors on top

      row.record = model_class.new(row.attributes.slice(*permitted_attributes))
      row.record.valid?
    end
  end
end

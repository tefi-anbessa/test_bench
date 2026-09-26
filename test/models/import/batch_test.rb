require "test_helper"

module Import
  class BatchTest < ActiveSupport::TestCase
    test "valid factory" do
      batch = build(:import_batch)
      assert batch.valid?, batch.errors.full_messages.join(", ")
    end

    test "importer_class and importer resolve via the Import::Base registry" do
      batch = build(:import_batch, importer_key: "tags")
      assert_equal Import::Tags, batch.importer_class
      assert_instance_of Import::Tags, batch.importer
      assert_same batch, batch.importer.batch
    end

    test "requires a user, project, importer_key, original_filename and file_data" do
      batch = Batch.new
      refute batch.valid?
      assert_includes batch.errors.attribute_names, :user
      assert_includes batch.errors.attribute_names, :project
      assert_includes batch.errors.attribute_names, :importer_key
      assert_includes batch.errors.attribute_names, :original_filename
      assert_includes batch.errors.attribute_names, :file_data
    end

    test "discipline is optional" do
      batch = build(:import_batch, discipline: nil)
      assert batch.valid?, batch.errors.full_messages.join(", ")
    end

    test "defaults expires_at to a day from creation" do
      batch = create(:import_batch)
      assert_in_delta 1.day.from_now, batch.expires_at, 5.seconds
    end

    test "does not override an explicitly set expires_at" do
      batch = create(:import_batch, expires_at: 3.days.from_now)
      assert_in_delta 3.days.from_now, batch.expires_at, 5.seconds
    end

    test "defaults to uploaded status" do
      batch = create(:import_batch)
      assert batch.uploaded?
    end

    test "expired scope only returns batches past their expiry" do
      fresh = create(:import_batch, expires_at: 1.hour.from_now)
      stale = create(:import_batch, expires_at: 1.hour.ago)

      assert_includes Batch.expired, stale
      refute_includes Batch.expired, fresh
    end
  end
end

require "test_helper"

module Import
  class BaseTest < ActiveSupport::TestCase
    test "Import::Tags is registered under 'tags'" do
      assert_equal Import::Tags, Import::Base.registered("tags")
      assert_equal Import::Tags, Import::Base.registered(:tags)
    end

    test "an unknown importer key raises a clear error" do
      error = assert_raises(ArgumentError) { Import::Base.registered("not_a_real_importer") }
      assert_match "not_a_real_importer", error.message
    end

    test "the batch's tempfile survives a garbage collection between reads" do
      user = create(:user)
      project = create(:project)
      batch = create(:import_batch,
        user: user, project: project,
        original_filename: "tags.csv", file_data: "Tag Number,Stage\nPT0001A,5\n")
      importer = batch.importer

      # Regression test for a real bug: #batch_file_path used to return only
      # a path string, with no other reference keeping the underlying
      # Tempfile object alive - which meant it was eligible for GC (and its
      # finalizer unlinks the file) immediately, independent of whether
      # something was still reading from that path. Forcing a GC here
      # reproduced ENOENT on a real user file before the fix (Import::Base
      # now holds the Tempfile object itself in @batch_tempfile).
      importer.headers
      GC.start
      assert_equal ["Tag Number", "Stage"], importer.headers
    end
  end
end

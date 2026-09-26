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
  end
end

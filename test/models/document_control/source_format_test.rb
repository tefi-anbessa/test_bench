require "test_helper"
require_relative "../../helpers/model_test_patterns"

module DocumentControl
  class SourceFormatTest < ActiveSupport::TestCase
    include ModelTestPatterns

    def setup
      setup_common_test_data # in model_test_patterns.rb
      setup_model_specific_data
    end
    
    def setup_model_specific_data
      @resource = create(:document_control_source_format, title: "Ruby on Rails", 
                          file_extension: ".rb", revision: "8.2")
    end

    test "title must be present" do
      @resource.title = nil
      refute @resource.valid?
      assert_includes @resource.errors[:title], I18n.t("errors.messages.blank")
    end
    
    test "title and revision must be unique" do
      duplicate = build(:document_control_source_format, title: @resource.title, revision: @resource.revision)
      refute duplicate.valid?
      assert_includes duplicate.errors[:revision], I18n.t("errors.messages.taken")
    end

  end
end

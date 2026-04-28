require "test_helper"

module DocumentControl
  class SourceFormatTest < ActiveSupport::TestCase

    def setup
      # Create project with standard disciplines
      @project = create(:project, title: "Source Format Model Test")
      @resource = create(:document_control_source_format)
    end

    # Common test patterns used for all model tests
    test "setup is valid" do
      assert @project.valid?
      assert @project.persisted?
    end

    def test_should_create_resource
      assert_difference '@resource.class.count', 1 do
        create(@resource.class.model_name.singular)
      end
    end

    def test_destroy_resource
      assert_difference '@resource.class.count', -1 do
        @resource.destroy
      end
  end

    test "title must be present" do
      @resource.title = nil
      refute @resource.valid?
      assert_includes @resource.errors[:title], I18n.t("errors.messages.blank")
    end

    test "title must not be too long" do
      @resource.title = "a" * 51
      refute @resource.valid?
      assert_includes @resource.errors[:title], I18n.t("errors.messages.too_long", count: 50)
    end
    
    test "title and revision must be unique" do
      duplicate = build(:document_control_source_format, title: @resource.title, revision: @resource.revision)
      refute duplicate.valid?
      assert_includes duplicate.errors[:revision], I18n.t("errors.messages.taken")
    end

    test "revision must not be too long" do
      @resource.revision = "a" * 21
      refute @resource.valid?
      assert_includes @resource.errors[:revision], I18n.t("errors.messages.too_long", count: 20)
    end

    test "file extension must not be too long" do
      @resource.file_extension = "a" * 11
      refute @resource.valid?
      assert_includes @resource.errors[:file_extension], I18n.t("errors.messages.too_long", count: 10)
    end

    test "label must be implemented" do
      assert_equal "#{@resource.title} #{@resource.revision}", @resource.label
    end

  end
end

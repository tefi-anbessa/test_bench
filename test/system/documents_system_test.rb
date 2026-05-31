# frozen_string_literal: true
require "application_system_test_case"
require "helpers/discipline_resource_system_tests"
class DocumentsSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include ActionView::Helpers::NumberHelper
  include DisciplineResourceSystemTests

  setup do
    setup_common_data
    setup_model_specific_data
  end

  def setup_model_specific_data
    @dt = create(:doc_type, discipline: @discipline)
    @resource = create(:document, doc_type: @dt, discipline: @discipline)
    @discipline_resource_index_header = I18n.t('documents.index.header', 
      scope_text: [@discipline.project.code, I18n.t("activerecord.models.discipline.one"), @discipline.long_label].join(' '))
    @project_resource_index_header = I18n.t('documents.index.header', 
      scope_text: [I18n.t("activerecord.models.project.one"), @project.label].join(': '))
    @project_resource_index_title = @discipline_resource_index_title = I18n.t('documents.index.title')
    # List fields that should appear in index. 
    # The generator will include test for sort link header for each column, 
    # and try to find an appropriate value field for the type.
    @index_fields = [:doc_number, :title]

    # List index fields that should have ransack search capability.
    # The generator will only test for "contains" fields (_cont).
    # Don't include numeric or date fields, add model specific tests for these later in this file.
    @search_fields = [:title]

    # List all fields that should appear in show (usually all)
    @show_fields = [:doc_number, :title, :notes]
    @show_associations = [:doc_type, :discipline]

    # List all fields that should appear in forms (usually all).
    # New and edit required separately because some models have read only fields that can't be edited.
    # Set a valid value for each field if required to be unique, set nil for factory default.
    # Document model has its own way to ensure uniqueness by setting serial internally.
    @new_fields = {doc_type_id: nil, title: nil, notes: nil}
    @edit_fields = {title: nil, notes: nil}

    # Set an attribute/s to be modified in edit test
    # Only working with text fields at present
    @edit_attributes = { title: "REVISED FOR TEST" }
  end

  def fill_in_model_specific_fields
    # No special fields in documents
  end
end

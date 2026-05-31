# frozen_string_literal: true
require "application_system_test_case"
require "helpers/discipline_resource_system_tests"
class DocTypesSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include ActionView::Helpers::NumberHelper
  include DisciplineResourceSystemTests

  setup do
    setup_common_data
    setup_model_specific_data
  end

  def setup_model_specific_data
    @accredited_user.grant(:document_controller, @discipline)
    @resource = create(:doc_type, discipline: @discipline)
    @discipline_resource_index_header = I18n.t('doc_types.index.header', 
      scope_text: [@discipline.project.code, I18n.t("activerecord.models.discipline.one"), @discipline.long_label].join(' '))
    @project_resource_index_header = I18n.t('doc_types.index.header', 
      scope_text: [I18n.t("activerecord.models.project.one"), @project.label].join(': '))
    @project_resource_index_title = @discipline_resource_index_title = I18n.t('doc_types.index.title')
    # List fields that should appear in index. 
    # The generator will include test for sort link header for each column, 
    # and try to find an appropriate value field for the type.
    @index_fields = [:code, :name, :description]

    # List index fields that should have ransack search capability.
    # The generator will only test for "contains" fields (_cont).
    # Don't include numeric or date fields, add model specific tests for these later in this file.
    @search_fields = [:code, :name, :description]

    # List all fields that should appear in show (should be all)
    @show_fields = [:code, :name, :description]

    # List all fields that should appear in forms (usually all).
    # New and edit required separately because some models have read only fields that can't be edited.
    # Set a valid value for each field if required to be unique, set nil for factory default.
    # Document model has its own way to ensure uniqueness by setting serial internally.
    @new_fields = {code: @resource.code.succ, name: nil, description: nil}
    @edit_fields = {code: @resource.code.succ, name: nil, description: nil}

    # Set an attribute/s to be modified in edit test
    # Only working with text fields at present
    @edit_attributes = { description: "REVISED FOR TEST" }
  end
  
  def fill_in_model_specific_fields
    # No special fields in doc types
  end

  # team_member cannot see doc_types except in selectors.
  undef test_team_member_navigating_to_project_resource_index

  def test_team_member_navigating_to_project_resource_index
    @team_member.grant(:document_controller, @project)
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit project_path(@project)
    assert_current_path project_path(@project)
    click_link(href: project_resource_index_path(@project))
    assert_current_path project_resource_index_path(@project)
    
    project_resource_index_assertions
    # Variable assertions
    assert_selector "a[href='#{project_path(@project)}']" # Link back to project show view
    refute_selector "a[href='#{new_discipline_resource_path(@discipline)}']" # Link to new resource
    assert_selector "a[href='#{resource_path(@resource)}']" # Link to resource show view
    assert_selector "a[href='#{edit_resource_path(@resource)}']" # document controller can edit resource
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # document controller cannot delete resource
  end
  undef test_team_member_navigating_to_discipline_resource_index
  undef test_team_member_navigating_to_resource_show_view

end

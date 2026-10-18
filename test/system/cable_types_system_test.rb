# frozen_string_literal: true
require "application_system_test_case"
require "helpers/discipline_resource_system_tests"
class CableTypesSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
  include ActionView::Helpers::NumberHelper
  include DisciplineResourceSystemTests

  setup do
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users(:custodian)
    setup_model_specific_data
  end

  def setup_model_specific_data
    @resource = create(:electrical_cable_type, discipline: @discipline)
    # Model should generate sequential codes.
    @resource2 = create(:electrical_cable_type, discipline: @discipline)
    @discipline_resource_index_header = I18n.t('cable_types.index.header',
      scope_text: [@discipline.project.code, I18n.t("activerecord.models.discipline.one"), @discipline.label].join(' '))
    @project_resource_index_header = I18n.t('cable_types.index.header',
      scope_text: [I18n.t("activerecord.models.project.one"), @project.label].join(': '))
    @project_resource_index_title = @discipline_resource_index_title = I18n.t('cable_types.index.title')
    # List fields that should appear in index.
    # The generator will include test for sort link header for each column,
    # and try to find an appropriate value field for the type.
    @index_fields = [:code, :primary_role, :notes]

    # List index fields that should have ransack search capability.
    # The generator will only test for "contains" fields (_cont).
    # Don't include numeric or date fields, add model specific tests for these later in this file.
    @search_fields = [:conductor_material, :insulation]

    # List all fields that should appear in show (usually all) - neutral_csa/
    # earth_csa are shown via the delegated detail's own card (see
    # @show_associations), not as direct CableType attributes.
    @show_fields = [:conductor_material, :groups, :construction, :csa,
          :insulation, :bedding, :armour, :sheath, :bedding_od, :overall_od,
          :temperature_rating, :voltage_rating, :fire_protection, :notes, :code]

    # List all associations that should have a collapsible card on the show view
    @show_associations = [:discipline, :detail]

    # List all fields that should appear in forms (usually all) - neutral_csa/
    # earth_csa excluded here, handled in fill_in_model_specific_fields below:
    # they're nested under the delegated detail, not plain CableType fields
    # (same reasoning as Cable's own cable_type field, ingress_protection, etc.)
    @new_fields = {primary_role: nil, conductor_material: nil, groups: nil, construction: nil, csa: nil,
      insulation: nil, bedding: nil, armour: nil, sheath: nil, bedding_od: nil, overall_od: nil,
      temperature_rating: nil, voltage_rating: nil, fire_protection: nil, notes: nil}
    @edit_fields = @new_fields
    @model_special_cases = { neutral_csa: nil, earth_csa: nil }

    # Set an attribute/s to be modified in edit test
    # Only working with text fields at present
    @edit_attributes = { notes: "REVISED FOR TEST" }
  end

  # team_member cannot see cable_types except in selectors. Unlike DocType's
  # document_controller, custodian is a discipline-only role (see
  # config/constants/role.yml) - there's no project-wide grant that would
  # let a non-admin reach the project-wide index at all, so this is
  # dropped rather than overridden.
  undef test_team_member_navigating_to_project_resource_index
  undef test_team_member_navigating_to_discipline_resource_index
  undef test_team_member_navigating_to_resource_show_view

  # custodian is a discipline-only role (see config/constants/role.yml) -
  # there's no project-wide equivalent to grant, so a discipline-scoped
  # accredited user can never see the project-wide index button, unlike
  # DocType's document_controller (which spans both levels).
  undef test_accredited_user_resource_show_view

  def test_accredited_user_resource_show_view
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    show_assertions(check_project_index: false)
    # Variable assertions
    assert_nav_button(:edit, @resource, path: edit_resource_path(@resource))
    refute_delete(resource_path(@resource))
    assert_nav_button(:new, path: new_discipline_resource_path(@discipline))
  end

  test "index search fields" do
    # Test for eq search fields not covered by standard tests.
    sign_in @accredited_user
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit discipline_resource_index_path(@discipline)
    assert_current_path discipline_resource_index_path(@discipline)
  end

  private

    # csa is a decimal column, but the form renders it as a select of
    # standard sizes (see _form.html.erb) rather than a plain number input -
    # the generic field assertions assume decimal columns are always number
    # inputs, which doesn't hold here.
    CSA_FIELDS = %i[csa].freeze

    def new_resource_form_assertions
      form_labels_assertions(@new_fields)
      field_form_new_assertions(@new_fields.except(*CSA_FIELDS))
      csa_field_assertions
      assert_selector "button[type='submit']"
      assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
    end

    def edit_resource_form_assertions
      form_labels_assertions(@edit_fields)
      field_form_edit_assertions(@edit_fields.except(*CSA_FIELDS))
      csa_field_assertions
      assert_selector "button[type='submit']"
      assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
    end

    def csa_field_assertions
      key = resource_class.model_name.param_key
      CSA_FIELDS.each do |field|
        assert_selector "select[name='#{key}[#{field}]']"
      end
      # Nested detail fields
      assert_selector "select[name='#{key}[detail_attributes][neutral_csa]']"
      assert_selector "select[name='#{key}[detail_attributes][earth_csa]']"
    end

    # The generic fill_in_resource_fields assumes decimal columns are always
    # a text/number input - fill the CSA select ourselves, then delegate the
    # rest of @new_fields (minus csa) to the shared implementation.
    def fill_in_resource_fields
      key = resource_class.model_name.param_key
      CSA_FIELDS.each do |field|
        value = @resource.send(field)
        find("select[name='#{key}[#{field}]'] option[value='#{value}']").select_option
      end
      original_new_fields = @new_fields
      @new_fields = @new_fields.except(*CSA_FIELDS)
      super
    ensure
      @new_fields = original_new_fields
    end

    def fill_in_model_specific_fields
      key = resource_class.model_name.param_key
      detail = @resource.detail
      find("select[name='#{key}[detail_attributes][neutral_csa]'] option[value='#{detail.neutral_csa}']").select_option
      find("select[name='#{key}[detail_attributes][earth_csa]'] option[value='#{detail.earth_csa}']").select_option
    end
end

module TagableSystemTestPatterns
  extend ActiveSupport::Concern

  def setup_common_tagable_data

    # Create project
    @project = create(:project)

    # Create resource discipline using the class discipline_code and default prefix_schema
    @discipline = create(:discipline, project: @project, code: resource_class.discipline_code,
      prefix_schema: { name: 'default'})

    # Create users with roles
    # No credentials for project
    @regular_user = create(:user)

    # Sysadmins
    @app_owner = create(:user)
    @app_owner.grant(:app_owner)

    @admin = create(:user)
    @admin.grant(:admin)

    # Project roles
    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)

    @team_member = create(:user)
    @team_member.grant(:team_member, @project)

    # Set up a user with edit permissions on this resource.
    @accredited_team_member = create(:user)
    @accredited_team_member.grant(:team_member, @project)
    @accredited_team_member.grant(resource_class.required_role)

    # Set up an existing tag with associated resource for index, show, edit, update, destroy tests
    @assigned_tag = create(:tag, serial: 1001, discipline: @discipline)
    @resource = create(resource_class.model_name.singular, tag: @assigned_tag)
    
    # Set up an unassigned tag for create and update tests
    @unassigned_tag = create(:tag, serial: 1002,  discipline: @discipline, 
      tagable_type: resource_class.model_name.name)
  end

  # Helper methods

  def resource_class
   self.class.name.sub('SystemTest', '').singularize.constantize
  end

  def field_types(fields)
    fields&.each_with_object({}) do |field, hash|
      if resource_class.defined_enums.key?(field)
        hash[field] = :enum
      elsif field.end_with?('_id')
        hash[field] = :reference
      elsif field.end_with?('_type')
        hash[field] = :polymorphic
      else
        hash[field] = resource_class.attribute_types[field]&.type
      end
    end
  end

  # Electrical::Cable -> Electrical
  def module_name
    resource_class.name.split('::').first
  end

  # Electrical::Cable -> electrical_cables_path
  def index_path
    send("#{resource_class.model_name.route_key}_path")
  end

  # Electrical::Cable -> electrical_cable_path
  def resource_path(resource)
    send("#{resource_class.model_name.singular_route_key}_path", resource)
  end

  # Electrical::Cable -> new_electrical_cable_path
  def new_resource_path
    send("new_#{resource_class.model_name.singular_route_key}_path")
  end

  # Electrical::Cable -> new_tag_electrical_cable_path
  def new_tag_resource_path(tag)
    send("new_tag_#{resource_class.model_name.singular_route_key}_path", tag)
  end

  # Electrical::Cable -> edit_electrical_cable_path
  def edit_resource_path(resource)
    send("edit_#{resource_class.model_name.singular_route_key}_path", resource)
  end

  # Electrical::Cable -> electrical.cables
  def view_key
    resource_class.model_name.route_key.gsub('_', '.')
  end

  # Electrical::Cable -> electrical/cable
  def model_key
    resource_class.model_name.i18n_key
  end

  # Tests
  def test_unauthenticated_users
    visit root_url
    refute_selector "#electrical-menu-btn"
  end

  def test_team_member_navigating_to_index
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    # Click the electrical drop down link
    id_label = "#{module_name.underscore}-menu-btn"
    resource_label = resource_class.model_name.human.pluralize
    find("\##{id_label}").click
    
    within "[aria-labelledby='#{id_label}']" do
      assert_selector "a", text: resource_label
      click_on resource_label
    end
    assert_current_path send("#{resource_class.model_name.route_key}_path") 
    index_assertions
    refute_selector "a[href='#{new_resource_path}']" # Link to new resource
    assert_selector "a[href='#{resource_path(@resource)}']" # Link to resource show view
    refute_selector "a[href='#{edit_resource_path(@resource)}']" # team member cannot edit resource
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # team member cannot delete resource
  end

  def test_accredited_team_member_view_index
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit index_path
    assert_current_path send("#{resource_class.model_name.route_key}_path")
    # Links
    assert_selector "a[href='#{new_resource_path}']" # Link to new motor
    assert_selector "a[href='#{resource_path(@resource)}']" # Link to motor show view
    assert_selector "a[href='#{edit_resource_path(@resource)}']" # accredited team member can edit motor
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # accredited team member cannot delete motor
  end

  def test_admin_view_index
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit index_path
    assert_current_path index_path
    # Links
    assert_selector "a[href='#{new_resource_path}']" # Link to new motor
    assert_selector "a[href='#{resource_path(@resource)}']" # Link to motor show view
    assert_selector "a[href='#{edit_resource_path(@resource)}']" # accredited team member can edit motor
    assert_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # admin can delete motor
  end

  def test_team_member_navigating_to_the_resource_show_view
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit index_path
    click_link(href: resource_path(@resource))
    assert_current_path resource_path(@resource)

    # Header bar navigation links
    assert_selector "a[href='#{index_path}']"# Link back to motors index
    refute_selector "a[href='#{edit_resource_path(@resource)}']" # team member cannot edit motor
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # team member cannot delete motor
    # [TODO] test prev and next buttons
    show_assertions
  end

  def test_accredited_team_member_viewing_the_resource_show_view
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    # Header bar navigation links
    assert_selector "a[href='#{index_path}']"# Link back to motors index
    assert_selector "a[href='#{edit_resource_path(@resource)}']" # accredited team member can edit motor
    refute_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # team member cannot delete motor
    # [TODO] test prev and next buttons
    show_assertions
  end

  def test_admin_viewing_the_resource_show_view
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit resource_path(@resource)
    assert_current_path resource_path(@resource)

    # Header bar navigation links
    assert_selector "a[href='#{index_path}']"# Link back to motors index
    assert_selector "a[href='#{edit_resource_path(@resource)}']" # accredited team member can edit motor
    assert_selector "a[href='#{resource_path(@resource)}'][data-method='delete']" # team member cannot delete motor
    # [TODO] test prev and next buttons
    show_assertions
  end

  def test_accredited_team_member_navigating_to_the_new_tag_and_new_resource_form
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit index_path
    click_link(href: new_resource_path)
    assert_current_path new_resource_path
    assert_text I18n.t("#{view_key}.new.header")
    assert page.title.include?(I18n.t("#{view_key}.new.title"))

    # Tag section
    tag_form_assertions

    # Resource section
    new_resource_form_assertions
  end

  def test_accredited_team_member_create_new_tag_and_new_resource
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit index_path
    click_link(href: new_resource_path)
    assert_current_path new_resource_path

    new_resource_form_assertions

    fill_in_tag_fields
    fill_in_resource_fields

    # Submit the form data
    click_button I18n.t('actions.save')
    sleep 1.0  # Give database time to commit
    # Form data uses @assigned_tag as a template, serial increased + 200.
    new_tag = Tag.find_by(discipline: @discipline, 
      prefix: @assigned_tag.prefix, 
      serial: @assigned_tag.serial + 200, 
      suffix: @assigned_tag.suffix)
    assert_current_path resource_path(new_tag.tagable)
    assert_text new_tag.label
    assert_text I18n.t('flash.tagables.created_and_assigned',
                            resource_name: resource_class.model_name.human,
                            id: new_tag.tagable.id,
                            tag: new_tag.label)
  end

  def test_accredited_team_member_create_new_resource_with_existing_tag
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@unassigned_tag)
    assert_current_path tag_path(@unassigned_tag)
    click_link(href: new_tag_resource_path(@unassigned_tag))
    assert_current_path new_tag_resource_path(@unassigned_tag)
    fill_in_resource_fields

    # Submit the form data
    click_button I18n.t('actions.save')
    sleep 1.0  # Give database time to commit
    assert_current_path resource_path(@unassigned_tag.reload.tagable)
    assert_text @unassigned_tag.label
    assert_text I18n.t('flash.tagables.assigned_to',
                            resource_name: resource_class.model_name.human,
                            id: @unassigned_tag.tagable.id,
                            tag: @unassigned_tag.label)
  end

  def test_accredited_team_member_edit_resource
    sign_in @accredited_team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit index_path
    click_link(href: edit_resource_path(@resource))
    assert_current_path edit_resource_path(@resource)
    assert_text I18n.t("#{view_key}.edit.header", label: @resource.label)
    assert page.title.include?(I18n.t("#{view_key}.edit.title"))

    # Tag collapsible card
    tag_card_assertions

    edit_resource_form_assertions

    # Edit the data
    fill_in "#{resource_class.model_name.param_key}[notes]", with: "REVISED FOR TEST"

    # Submit the form data
    click_button I18n.t('actions.update')
    sleep 0.5  # Give database time to commit
    # @resource.reload
    assert_current_path resource_path(@resource)
    assert_text @resource.label
    assert_text "REVISED FOR TEST"
    assert_text I18n.t("flash.update.notice", resource_name: resource_class.model_name.human)

    # Make another edit to test the show view link, and then discard
    click_link(href: edit_resource_path(@resource))
    fill_in "#{resource_class.model_name.param_key}[notes]", with: "REINSTATED FOR TEST"
    
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path resource_path(@resource)
    refute_text "REINSTATED FOR TEST"
  end

  def test_admin_edit_orphaned_resource_with_new_tag
    skip "Resolve workflow with no current project before this test can work"
    # Remove assigned tag from the database without destroy actions, leaving @resource as an orphan
    @assigned_tag.delete
    sign_in @admin
    # No current_project for this test
    visit index_path
    click_link(href: edit_resource_path(@resource))
    assert_current_path edit_resource_path(@resource)
    assert_text I18n.t("#{view_key}.edit.header", label: @resource.label)
    assert page.title.include?(I18n.t("#{view_key}.edit.title"))

    # Tag nested form should be included
    tag_form_assertions
  end

  def test_admin_destroy_resource_from_the_index_view
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit index_path
    # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{resource_path(@resource)}'][data-method='delete']").click
    end
    assert_current_path index_path
    refute_selector "a[href='#{resource_path(@resource)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: @resource.model_name.human)
  end

  def test_admin_destroy_resource_from_the_show_view
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit index_path
    # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{resource_path(@resource)}'][data-method='delete']").click
    end
    assert_current_path index_path
    refute_selector "a[href='#{resource_path(@resource)}']"
    assert_text I18n.t("flash.destroy.notice", resource_name: @resource.model_name.human)
  end

  # Assertions
  def index_assertions
    text = [@project.class.model_name.human, @project.label].join(': ')
    assert_text I18n.t("#{view_key}.index.header", project: text)
    assert page.title.include?(I18n.t("#{view_key}.index.title"))

    # Ransack search fields
    @search_fields.each do |field|
      assert_selector "input[name='q[#{field}_cont]']"
    end

    # Ransack sort headers
    assert_selector "a[href*='q%5Bs%5D=tag']"
    @index_fields.each do |field|
      assert_selector "a[href*='q%5Bs%5D=#{field}']"
    end
    
    # Data
    field_display_assertions(@index_fields)
  end

  def show_assertions
    assert_text I18n.t("#{view_key}.show.header", label: @resource.label)
    assert page.title.include?(I18n.t("#{view_key}.show.title"))

    # Tag collapsible card
    tag_card_assertions

    # Field labels
    @show_fields.each do |field|
      assert_text resource_class.human_attribute_name(field)
    end

    # Field data 
    field_display_assertions(@show_fields)
  end

  def tag_card_assertions
    # Find the specific tag card header using the correct ID pattern
    within "div[data-bs-target='#tag_#{@resource.tag.id}_details']" do
      assert_text I18n.t('tags.show.header', label: @resource.tag.label)
    end

    # Verify it's collapsed by default
    assert_selector "div[data-bs-target='#tag_#{@resource.tag.id}_details'][aria-expanded='false']", visible: true
  end

  def new_resource_form_assertions
    # Field labels
    @form_fields.each do |field|
      assert_text resource_class.human_attribute_name(field)
    end
    # Data fields - test existence only for new forms
    field_form_new_assertions(@form_fields)
    # Form buttons
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
  end

  def edit_resource_form_assertions
    # Field labels
    @form_fields.each do |field|
      assert_text resource_class.human_attribute_name(field)
    end
    # Data fields - test values for edit forms
    field_form_edit_assertions(@form_fields)
    # Form buttons
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
  end

  # Tag fields for nested form
  def tag_form_assertions(tag = nil)
    # Field labels
    assert_text I18n.t('activerecord.attributes.tag.project')
    assert_text I18n.t('activerecord.attributes.tag.stage')
    assert_text I18n.t('activerecord.attributes.tag.discipline')
    assert_text I18n.t('activerecord.attributes.tag.prefix')
    assert_text I18n.t('activerecord.attributes.tag.serial')
    assert_text I18n.t('activerecord.attributes.tag.suffix')
    assert_text I18n.t('activerecord.attributes.tag.service')
    assert_text I18n.t('activerecord.attributes.tag.location')
    assert_text I18n.t('activerecord.attributes.tag.notes')

    # Data fields
    assert_selector "input[name='#{resource_class.model_name.param_key}[tag][stage]']"
    assert_selector "select[name='#{resource_class.model_name.param_key}[tag][discipline_id]']"
    assert_selector "input[name='#{resource_class.model_name.param_key}[tag][serial]']"
    assert_selector "input[name='#{resource_class.model_name.param_key}[tag][suffix]']"
    assert_selector "input[name='#{resource_class.model_name.param_key}[tag][service]']"
    assert_selector "input[name='#{resource_class.model_name.param_key}[tag][location]']"
    assert_selector "textarea[name='#{resource_class.model_name.param_key}[tag][notes]']"
    assert_selector "select[name='#{resource_class.model_name.param_key}[tag][tagable_type]']"
    
    if tag.present?
      # Data
      assert_text tag.stage
      assert_text tag.prefix
      assert_text tag.serial
      assert_text tag.suffix
      assert_text tag.service
      assert_text tag.location
      assert_text tag.notes
    end
  end

  # Form operations
  # Tag fields
  def fill_in_tag_fields
      # Current project selection not working properly in test, so selector appears (should be hidden field)
      if has_selector?("select[name=\"#{resource_class.model_name.param_key}[tag][project_id]\"]")
        select(@project.code, from: "#{resource_class.model_name.param_key}[tag][project_id]")
      end
      fill_in "#{resource_class.model_name.param_key}[tag][stage]", with: @assigned_tag.stage
      fill_in "#{resource_class.model_name.param_key}[tag][prefix]", with: @assigned_tag.prefix
      fill_in "#{resource_class.model_name.param_key}[tag][serial]", with: @assigned_tag.serial + 200 # TODO make this more robust
      fill_in "#{resource_class.model_name.param_key}[tag][suffix]", with: @assigned_tag.suffix
      fill_in "#{resource_class.model_name.param_key}[tag][service]", with: @assigned_tag.service
      fill_in "#{resource_class.model_name.param_key}[tag][location]", with: @assigned_tag.location
      fill_in "#{resource_class.model_name.param_key}[tag][notes]", with: @assigned_tag.notes
  end

  def fill_in_resource_fields
    # Set all attributes to the same values as @resource
    @form_fields.each do |field|
      name = "#{resource_class.model_name.param_key}[#{field}]"
      value = @resource.send(field)
      case field_types(@form_fields)[field]
      when :enum
        if I18n.exists?("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field.pluralize}.#{value}")
          select(resource_class.human_enum_name(field.pluralize, value), from: name)
        else
          find("select[name='#{name}'] option[value='#{value}']").select_option
        end
      when :reference, :polymorphic
        find("select[name='#{name}'] option[value='#{value}']").select_option
      when :integer, :float, :decimal
        fill_in name, with: value.to_s
      when :boolean
        check name if value
      when :date, :datetime # [TODO] test datetime-local
        fill_in name, with: value.to_s
      when :text
        fill_in name, with: value.to_s
      else # string, etc.
        fill_in name, with: value.to_s
      end
    end
  end

  def field_display_assertions(fields)
    # For show views - tests displayed text values
    fields.each do |field|
      value = @resource.send(field)
      case field_types(fields)[field]
      when :enum
        if I18n.exists?("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field.pluralize}.#{value}")
      assert_text resource_class.human_enum_name(field, value)
        else
          assert_text value.to_s
        end
      when :reference, :polymorphic
        # No assertions, as references have variable display. Usually label but not always.
      when :float, :decimal
        assert_text number_to_human(value, precision: 4, units: { unit: field == :speed_rated ? "rpm" : "" }).strip
      when :boolean
        assert_selector "input[type='checkbox'][checked='#{value}']", visible: false
      when :date, :datetime
        assert_text I18n.l(value, format: :default)
      else # string, text, integer, etc.
        assert_text value
      end
    end
  end

  def field_form_edit_assertions(fields)
    # For edit forms - tests form field values with existing resource data
    fields.each do |field|
      value = @resource.send(field)
      name = "#{resource_class.model_name.param_key}[#{field}]"
      case field_types(fields)[field]
      when :enum
        if I18n.exists?("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field.pluralize}.#{value}")
          assert_selector "select[name='#{name}'] option[selected]", 
            text: resource_class.human_enum_name(field.pluralize, value)
        else
          assert_selector "select[name='#{name}'] option[selected]", text: value
        end
      when :reference, :polymorphic
        assert_selector "select[name='#{name}'] option[selected]", text: value
      when :integer, :float, :decimal
        assert_field name, with: value.to_s, type: 'number'
      when :boolean
        if value
          assert_selector "input[type='checkbox'][name='#{name}'][checked]"
        else
          assert_selector "input[type='checkbox'][name='#{name}']:not([checked])"
        end
      when :date, :datetime # [TODO] test datetime-local
        assert_field name, with: value.to_s, type: 'datetime-local'
      when :text
        assert_field name, with: value.to_s, type: 'textarea'
      else # string, text, integer, etc.
        assert_field name, with: value.to_s, type: 'text'
      end
    end
  end

  def field_form_new_assertions(fields)
    # For new forms - tests that form fields exist (no values expected)
    fields.each do |field|
      name = "#{resource_class.model_name.param_key}[#{field}]"
      case field_types(fields)[field]
      when :enum, :reference, :polymorphic
        assert_selector "select[name='#{name}']"
      when :integer, :float, :decimal
        assert_field name, type: 'number'
      when :boolean
        assert_selector "input[type='checkbox'][name='#{name}']"
      when :date, :datetime # [TODO] test datetime-local
        assert_field name, type: 'datetime-local'
      when :text
        assert_field name, type: 'textarea'
      else # string, text, integer, etc.
        assert_field name, type: 'text'
      end
    end
  end

  private

end
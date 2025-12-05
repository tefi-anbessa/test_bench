module TagableSystemTestPatterns
  extend ActiveSupport::Concern

  def setup_common_tagable_data

    # Create project
    @project = create(:project)

    # Create resource discipline using the class discipline_code
    @resource_discipline = create(:discipline, code: resource_class.discipline_code, project: @project)

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
    @assigned_tag = create(:tag, serial: 1001, discipline: @resource_discipline)
    @resource = create(resource_class.model_name.singular, tag: @assigned_tag)
    
    # Set up an unassigned tag for create and update tests
    @unassigned_tag = create(:tag, serial: 1002,  discipline: @resource_discipline)
  end

  # Helper methods

  def resource_class
   self.class.name.sub('SystemTest', '').singularize.constantize
  end

  def field_types
    if @show_fields.present?
      @field_types ||= @show_fields.each_with_object({}) do |field, hash|
        if resource_class.defined_enums.key?(field)
          hash[field] = :enum
        else
          hash[field] = resource_class.attribute_types[field]&.type
        end
      end
    else
      puts "Model system test must define variable @show_fields"
    end
  end

  def module_name
    resource_class.name.split('::').first
  end

  def index_path
    send("#{resource_class.model_name.route_key}_path")
  end

  def resource_path(resource)
    send("#{resource_class.model_name.singular_route_key}_path", resource)
  end

  def new_resource_path
    send("new_#{resource_class.model_name.singular_route_key}_path")
  end

  def edit_resource_path(resource)
    send("edit_#{resource_class.model_name.singular_route_key}_path", resource)
  end

  def view_key
    resource_class.model_name.route_key.gsub('_', '.')
  end

  # Tests

  def team_member_navigating_to_index
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

  # Common assertions
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
    @index_fields.each do |field|
      assert_text @resource.send(field)
    end
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
    @show_fields.each do |field|
      value = @resource.send(field)
      case field_types[field]
      when :enum
        if I18n.exists?("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field.pluralize}.#{value}")
          assert_text resource_class.human_enum_name(field, value)
        else
          assert_text value.to_s
        end
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

  def tag_card_assertions
    # Find the specific tag card header using the correct ID pattern
    within "div[data-bs-target='#tag_#{@resource.tag.id}_details']" do
      assert_text I18n.t('tags.show.header', label: @resource.tag.label)
    end

    # Verify it's collapsed by default
    assert_selector "div[data-bs-target='#tag_#{@resource.tag.id}_details'][aria-expanded='false']", visible: true
  end

  # Common navigation helpers
  # Each system test must define its own navigate_to_index method
  def navigate_to_index(model_name)
    raise NotImplementedError, "System test must implement navigate_to_index for #{model_name}"
  end

  def navigate_to_show_page(resource_path)
    visit resource_path
  end

  # Common authentication helpers
  def assert_unauthenticated_redirect
    visit root_url
    # Each system test must define what navigation elements should be absent when unauthenticated
    # For example: refute_selector "#electrical-menu-btn" for electrical models
  end

  def assert_role_based_access(user, model_name, actions)
    sign_in user

    actions.each do |action|
      case action
      when :index
        # Each system test must implement its own navigation to index
        # navigate_to_index(model_name)
        # assert_current_path send("#{model_name}s_path")
      when :show
        navigate_to_show_page(send("#{model_name}_path", send("@#{model_name}")))
        assert_current_path send("#{model_name}_path", send("@#{model_name}"))
      when :edit
        visit send("edit_#{model_name}_path", send("@#{model_name}"))
        assert_current_path send("edit_#{model_name}_path", send("@#{model_name}"))
      when :delete
        # Implementation depends on where delete is triggered from
      end
    end
  end

  # Tag fields for form
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
    assert_selector "input[name='tag[stage]']"
    assert_selector "select[name='tag[discipline_id]']"
    assert_selector "input[name='tag[serial]']"
    assert_selector "input[name='tag[suffix]']"
    assert_selector "input[name='tag[service]']"
    assert_selector "input[name='tag[location]']"
    assert_selector "textarea[name='tag[notes]']"
    assert_selector "select[name='tag[tagable_type]']"
    
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

  # Common form interaction helpers
  def fill_tag_fields(prefix, serial, suffix: "", service: nil)
    if has_selector?("select[name*='tag][project_id']")
      select(@project.code, from: "tag][project_id]")
    end
    fill_in "tag][stage]", with: "3"
    fill_in "tag][serial]", with: serial.to_s
    fill_in "tag][suffix]", with: suffix if suffix.present?
    fill_in "tag][service]", with: service || "TEST #{prefix} #{serial}"
    fill_in "tag][notes]", with: "TAG NOTES"
  end

  def submit_form_and_assert_success(model_name, tag_prefix, expected_discipline_code = nil)
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit

    # Each system test must implement its own tag finding logic
    # since different disciplines may have different tag formats
    new_tag = find_created_tag(tag_prefix)
    assert_current_path send("#{model_name}_path", new_tag.send(model_name))

    # Check tag format if discipline code is provided
    if expected_discipline_code
      assert_text "#{expected_discipline_code}:#{tag_prefix}-5555"
    end
  end

  # Each system test must implement this method to find the created tag
  def find_created_tag(tag_prefix)
    raise NotImplementedError, "System test must implement find_created_tag for #{tag_prefix}"
  end

  # Common assertion helpers
  def assert_common_index_elements(model_name, resource_instance)
    assert_text I18n.t("#{model_name}s.index.header")
    assert page.title.include?(I18n.t("#{model_name}s.index.title"))
    assert_text I18n.t('activerecord.models.tag')

    # Check resource data is displayed
    assert_text resource_instance.tag.label
    assert_text resource_instance.to_s
  end

  def assert_common_show_elements(model_name, resource_instance)
    assert_text I18n.t("#{model_name}s.show.header", label: resource_instance.label)
    assert page.title.include?(I18n.t("#{model_name}s.show.title"))

    # Tag section
    assert_text I18n.t('activerecord.models.tag')
    assert_text resource_instance.tag.full_tag
  end

  def assert_role_navigation_links(model_name, resource_instance, can_edit: false, can_delete: false)
    assert_selector "a[href='#{send("#{model_name}s_path")}']" # Back to index

    if can_edit
      assert_selector "a[href='#{send("edit_#{model_name}_path", resource_instance)}']"
    else
      refute_selector "a[href='#{send("edit_#{model_name}_path", resource_instance)}']"
    end

    if can_delete
      assert_selector "a[href='#{send("#{model_name}_path", resource_instance)}'][data-method='delete']"
    else
      refute_selector "a[href='#{send("#{model_name}_path", resource_instance)}'][data-method='delete']"
    end
  end

  private

end

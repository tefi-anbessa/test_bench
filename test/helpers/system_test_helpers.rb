# frozen_string_literal: true
require "test_helper"
require "helpers/test_setup_helpers"
module SystemTestHelpers
  extend ActiveSupport::Concern
  include TestSetupHelpers

  def setup_common_data
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
  end

  private # Helper methods

    def resource_class
      self.class.name.sub('SystemTest', '').singularize.constantize
    end

    def field_type(field)
      if resource_class.defined_enums.key?(field.to_s)
        if I18n.exists?("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field.to_s.pluralize}")
          :translated_enum
        else
          :enum
        end
      elsif association = resource_class.reflect_on_association(field)
        if association.polymorphic?
          :polymorphic
        else
          :reference
        end
      else
        resource_class.type_for_attribute(field)&.type
      end
    end

    def association_for_field(klass, field_name)
      klass.reflect_on_all_associations(:belongs_to)
           .find { |a| a.foreign_key.to_s == field_name.to_s }
    end

    # Electrical::Cable -> Electrical
    # Document -> nil
    def module_name
        resource_class.name.split('::').count > 1 ? resource_class.name.split('::').first : nil
    end

    # Swatch -> swatches_path
    def index_path
      send("#{resource_class.model_name.route_key}_path")
    end

    # Document -> project_documents_path
    def project_resource_index_path(project)
      send("project_#{resource_class.model_name.route_key}_path", project)
    end

    # Document -> discipline_documents_path(discipline)
    # Electrical::Cable -> discipline_electrical_cables_path(discipline)
    def discipline_resource_index_path(discipline)
      send("discipline_#{resource_class.model_name.route_key}_path", discipline)
    end

    # Document -> document_path
    # Electrical::Cable -> electrical_cable_path
    def resource_path(resource)
      send("#{resource_class.model_name.singular_route_key}_path", resource)
    end

    # Swatch -> new_swatch_path
    def new_resource_path
      send("new_#{resource_class.model_name.singular_route_key}_path")
    end

    # Document -> new_document_path(discipline)
    # Electrical::Cable -> new_discipline_electrical_cable_path(discipline)
    def new_discipline_resource_path(discipline)
      send("new_discipline_#{resource_class.model_name.singular_route_key}_path", discipline)
    end

    # Electrical::Cable -> new_tag_electrical_cable_path
    def new_tag_resource_path(tag)
      send("new_tag_#{resource_class.model_name.singular_route_key}_path", tag)
    end

    # Document -> edit_document_path
    # Electrical::Cable -> edit_electrical_cable_path
    def edit_resource_path(resource)
      send("edit_#{resource_class.model_name.singular_route_key}_path", resource)
    end

    # Document -> documents
    # Electrical::Cable -> electrical.cables
    # Electrical::CableType -> electrical.cable_types
    def view_key
      resource_class.model_name.name.gsub("::", ".").underscore.pluralize
    end

    def assert_sort_link(field, label)
      link = find("table thead a", text: label, exact_text: true)
      uri = URI.parse(link[:href])
      params = Rack::Utils.parse_nested_query(uri.query)
      assert_equal field.to_s, params.dig("q", "s")&.split.first
    end
    
    # Assertions
    def index_assertions
      assert_text @index_header
      assert page.title.include?(@index_title)
      index_field_assertions
    end
    
    # This assertion is generalised for project resource indexes, 
    # the including module shall provide the expected header and title as instance variables
    def project_resource_index_assertions
      assert_text @project_resource_index_header
      assert page.title.include?(@project_resource_index_title)

      index_field_assertions
    end

    def index_field_assertions
      # Ransack search fields
      @search_fields.each do |field|
        case field_type(field)
        when :integer
          assert_selector "input[name='q[#{field}_eq]']"
        else
          assert_selector "input[name='q[#{field}_cont]']"
        end
      end

      # Ransack sort headers
      @index_fields.each do |field|
        assert_selector "a[href*='q%5Bs%5D=#{field}']" unless field_type(field) == :text
      end
      
      # Data
      field_display_assertions(@index_fields)
    end

    def show_assertions
      assert_text I18n.t("#{view_key}.show.header", label: @resource.long_label)
      assert page.title.include?(I18n.t("#{view_key}.show.title"))

      # Field labels
      @show_fields.each do |field|
        assert_text I18n.t("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field}")
      end

      # Field data 
      field_display_assertions(@show_fields)

      # Associations
      @show_associations.each do |association|
        if @resource.send(association).present?
          collapsible_assertions(@resource, association)
        else
          # Text for unassigned association varies depending on association type.
          # If it is important, test it in the calling class.
        end
      end
    end

    def collapsible_assertions(object, association)
      assert object.respond_to?(association), "Object #{object.class} does not respond to #{association}"
      record = object.public_send(association)
      id = record.id
      component_id = "#{record.class.model_name.element}_#{id}_details"
      header_id = "#{component_id}_header"
      # Should start collapsed
      refute_selector "##{component_id}", visible: true
      assert_selector "##{component_id}", visible: :all
      find("##{header_id}").click
      assert_selector "##{component_id}.show", visible: :all
      # Card shall include a link to the associated resource
      assert_link href: polymorphic_path(record)
    end

    def children_collapsible_assertions(parent, association)
      record = parent.public_send(association)
      component_id = "#{parent.model_name.element}_#{association}_links"
      header_id = "#{component_id}_header"
      # Should start collapsed
      refute_selector "##{component_id}", visible: true
      assert_selector "##{component_id}", visible: :all
      find("##{header_id}").click
      assert_selector "##{component_id}.show", visible: :all
      # Card shall include a link to each child resource
      record.each do |child|
        assert_link href: polymorphic_path(child)
      end
    end

    def tag_card_assertions
      collapsible_assertions(@resource, :tag)
    end

    def new_resource_form_assertions
      # Field labels
      form_labels_assertions(@new_fields)
      # Data fields - test existence only for new forms
      field_form_new_assertions(@new_fields)
      # Form buttons
      assert_selector "button[type='submit']"
      assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
    end

    def edit_resource_form_assertions
      # Field labels
      form_labels_assertions(@edit_fields)
      # Data fields - test values for edit forms
      field_form_edit_assertions(@edit_fields)
      # Form buttons
      assert_selector "button[type='submit']"
      assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
    end

    def form_labels_assertions(fields)
      # Field labels
      fields.each do |field, value|
        case field_type(field)
        when :reference
          if I18n.exists?("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field}_id")
            label = I18n.t("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field}_id")
          else
            associated = resource_class.reflect_on_association(field).klass
            label = I18n.t("activerecord.models.#{associated.model_name.i18n_key}.one")
          end
          assert_text label
        when :polymorphic
          assert_text I18n.t("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field}_id")
          assert_text I18n.t("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field}_type")
        else
          assert_text I18n.t("activerecord.attributes.#{resource_class.model_name.i18n_key}.#{field}")
        end
      end
    end

    # Tag fields for nested form
    def tag_form_assertions(tag = nil)
      # Field labels
      assert_text I18n.t('activerecord.attributes.tag.stage')
      assert_text I18n.t('activerecord.attributes.tag.prefix')
      assert_text I18n.t('activerecord.attributes.tag.serial')
      assert_text I18n.t('activerecord.attributes.tag.suffix')
      assert_text I18n.t('activerecord.attributes.tag.service')
      assert_text I18n.t('activerecord.attributes.tag.location')
      assert_text I18n.t('activerecord.attributes.tag.notes')
      assert_text I18n.t('activerecord.attributes.tag.tagable_type')

      # Data fields
      # [TODO: Add a conditional test for prefix fields depending on schema]
      assert_field "#{resource_class.model_name.param_key}[tag][stage]", with: tag.present? ? tag.stage : ""
      assert_field "#{resource_class.model_name.param_key}[tag][serial]", with: tag.present? ? tag.serial.to_s.rjust(4, '0') : "0000"
      assert_field "#{resource_class.model_name.param_key}[tag][suffix]", with: tag.present? ? tag.suffix : ""
      assert_field "#{resource_class.model_name.param_key}[tag][service]", with: tag.present? ? tag.service : ""
      assert_field "#{resource_class.model_name.param_key}[tag][location]", with: tag.present? ? tag.location : ""
      assert_field "#{resource_class.model_name.param_key}[tag][notes]", with: tag.present? ? tag.notes : ""
      assert_field "#{resource_class.model_name.param_key}[tag][tagable_type]", with: tag.present? ? tag.tagable_type : "#{resource_class.name}",
             disabled: true
    end

    # Form operations
    # Tag fields
    def fill_in_tag_fields
      fill_in "#{resource_class.model_name.param_key}[tag][stage]", with: @tag.stage
      fill_in_prefix_field
      @saved_serial = @tag.next_serial
      fill_in "#{resource_class.model_name.param_key}[tag][serial]", with: @saved_serial
      fill_in "#{resource_class.model_name.param_key}[tag][suffix]", with: @tag.suffix
      fill_in "#{resource_class.model_name.param_key}[tag][service]", with: @tag.service
      fill_in "#{resource_class.model_name.param_key}[tag][location]", with: @tag.location
      fill_in "#{resource_class.model_name.param_key}[tag][notes]", with: @tag.notes
    end

    def fill_in_prefix_field
      # Tagable models should set prefix in accordance with their discipline prefix schema.
      # Fall back to selecting the first key from each selector field
      case @discipline.schema_for_form[:type]
      when 'default'
        fill_in "#{resource_class.model_name.param_key}[tag][prefix]", with: @tag.prefix
        @saved_prefix = @tag.prefix
      when 'dim1'
        @saved_prefix = @discipline.schema_for_form.with_indifferent_access[:prefixes].keys.last
        find("select[name='prefix_select'] option[value='#{@saved_prefix}']").select_option
      when 'dim2'
        value1 = @discipline.schema_for_form.with_indifferent_access[:part1].keys.last
        value2 = @discipline.schema_for_form.with_indifferent_access[:part2].keys.last
        @saved_prefix = value1 + value2
        find("select[name='part1'] option[value='#{value1}']").select_option
        find("select[name='part2'] option[value='#{value2}']").select_option
      when 'isa51'
        mv = @discipline.schema_for_form.with_indifferent_access[:measured_variable].keys.last
        of = @discipline.schema_for_form.with_indifferent_access[:output_function].keys.last
        @saved_prefix = mv + of
        find("select[name='measured_variable'] option[value='#{mv}']").select_option
        find("select[name='output_function'] option[value='#{of}']").select_option
      end
    end

    def fill_in_resource_fields
      # Set all attributes to the values provided, default to @resource if nil
      @new_fields.each do |field, value|
        key = "#{resource_class.model_name.param_key}"
        name = "#{key}[#{field}]"
        value = value.nil? ? @resource.send(field) : value
        case field_type(field)
        when :translated_enum
          select(resource_class.human_enum_name(field.to_s.pluralize, value), from: name)
        when :enum
          find("select[name='#{name}'] option[value='#{value}']").select_option
        when :reference
          if value.is_a?(ActiveRecord::Base)
            find("select[name='#{key}[#{field}_id]'] option[value='#{value.id}']").select_option
          end
        when :polymorphic
          if value.is_a?(ActiveRecord::Base)
            find("select[name='#{key}[#{field}_type]'] option[value='#{value.class.name}']").select_option
            find("select[name='#{key}[#{field}_id]'] option[value='#{value.id}']").select_option
          end
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
      fill_in_model_specific_fields
    end

    def field_display_assertions(fields)
      # For show views - tests displayed text values
      fields.each do |field|
        value = @resource.send(field)
        case field_type(field)
        when :translated_enum
          assert_text resource_class.human_enum_name(field, value)
        when :enum
          assert_text value.to_s
        when :reference, :polymorphic
          # No assertions, as references have variable display. Test in including module.
        when :float, :decimal
          # No assertions, format varies. Test in including module.
        when :boolean
          # [TODO decide on a standard clear presentation for booleans and test it.]
          # assert_selector "input[type='checkbox'][checked='#{value}']", visible: false
        when :date, :datetime
          assert_text I18n.l(value, format: :default)
        when :text
          assert_text value.to_s.first(10)
        else # string, text, integer, etc.
          assert_text value.to_s
        end
      end
    end

    def field_form_edit_assertions(fields)
      # For edit forms - tests form field values with existing resource data
      fields.each do |field, value|
        key = "#{resource_class.model_name.param_key}"
        name = "#{key}[#{field}]"
        value = @resource.send(field) # Value will initially be original value from @resource
        case field_type(field)
        when :translated_enum
          assert_selector "select[name='#{name}'] option[selected]", 
              text: resource_class.human_enum_name(field.to_s.pluralize, value)
        when :enum
          assert_selector "select[name='#{name}'] option[selected]", text: value
        when :reference
          assert_selector "select[name='#{key}[#{field}_id]']"
        when :polymorphic
          assert_selector "select[name='#{key}[#{field}_type]']"
          assert_selector "select[name='#{key}[#{field}_id]']"
        when :integer, :float, :decimal
          assert_field name, with: value.to_s, type: 'number'
        when :boolean
          assert_field name, checked: value
        when :date, :datetime # [TODO] test datetime-local
          expected = value&.strftime("%Y-%m-%dT%H:%M")
          assert_field name, with: expected
        when :text
          assert_field name, with: value.to_s, type: 'textarea'
        else # string, text, integer, etc.
          assert_field name, with: value.to_s, type: 'text'
        end
      end
    end

    def field_form_new_assertions(fields)
      # For new forms - tests that form fields exist (no values expected)
      fields.each do |field, value|
        key = "#{resource_class.model_name.param_key}"
        name = "#{key}[#{field}]"
        case field_type(field)
        when :translated_enum, :enum
          assert_selector "select[name='#{name}']"
        when :reference
          assert_selector "select[name='#{key}[#{field}_id]']"
        when :polymorphic
          assert_selector "select[name='#{key}[#{field}_type]']"
          assert_selector "select[name='#{key}[#{field}_id]']"
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

end
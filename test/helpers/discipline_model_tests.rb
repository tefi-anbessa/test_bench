# This module provides common test patterns for models associated with a discipline, but not tagged.
# Include this in your model test and all the test methods will run.
module DisciplineModelTests
  extend ActiveSupport::Concern
# Setup common to typical resource models other than tagables.
  def setup_common_test_data
    # Create project with standard disciplines
    @project = create(:project, title: "#{resource_class} Model Test")

    # Set resource discipline using the class' module name
    @resource_discipline = @project.disciplines.find_by(name: resource_class.module_parent_name)
  end

  # Common test patterns used for all model tests
  def test_common_setup_is_valid
    assert @project.valid?
    assert @project.persisted?
    assert @resource_discipline.valid?
    assert @resource_discipline.persisted?
  end

  # Ensure specific model test has created @resource instance variable
  def test_model_specific_setup_is_valid
    assert @resource.valid?
    assert @resource.persisted?
  end

  def test_factory_default_should_create_resource_with_valid_attributes
    new_resource = build(@resource.class.model_name.singular)
    assert new_resource.valid?
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

  private

    # Helper methods
    def resource_class
    self.class.name.sub('Test', '').singularize.constantize
    end

end
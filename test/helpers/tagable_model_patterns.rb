# This module provides common test patterns for tagable models
# Include this in your controller test and all the test methods will run.
module TagableModelPatterns
  extend ActiveSupport::Concern
# Setup common to all tagable models
  def setup_common_test_data
    @project = create(:project)

    # Create resource discipline using the code provided by the tagable controller test
    @resource_discipline = create(:discipline, code: resource_class.discipline_code, project: @project)

    # Factory default unique tag will be "A:AA-0001"
    @tag = create(:tag, :unique_tag, discipline: @resource_discipline)
  end

  # Common test patterns used for all tagable controller tests
  def test_common_setup_is_valid
    assert @project.valid?
    assert @project.persisted?
    assert @resource_discipline.valid?
    assert @resource_discipline.persisted?
    assert @tag.valid?
    assert @tag.persisted?
    assert @tag.discipline == @resource_discipline
    assert @tag.project == @project
  end

  def test_model_specific_setup_is_valid
    assert @resource.valid?
    assert @resource.tag == @tag
    assert @tag.tagable == @resource
  end

  def test_factory_default_should_create_resource_with_valid_attributes
    new_resource = build(@resource.class.model_name.singular)
    assert new_resource.valid?
  end

  def test_should_create_resource_as_tagable_linked_to_existing_tag
    new_tag = create(:tag, :unique_tag, discipline: @resource_discipline)
    assert_difference '@resource.class.count', 1 do
      new_resource = create(@resource.class.model_name.singular, tag: new_tag)
      new_tag.reload
      assert_equal new_tag.tagable, new_resource
    end
  end

  def test_destroy_resource_should_nullify_tagable
    @resource.destroy
    
    @tag.reload
    assert_nil @tag.tagable
    assert_nil @tag.tagable_type
    assert_nil @tag.tagable_id
  end

  def test_destroy_tag_should_destroy_resource
    resource_id = @resource.id
    assert_difference '@resource.class.count', -1 do
      @tag.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { resource_class.find(resource_id) }
  end

  private

  # Helper methods

  def resource_class
   self.class.name.sub('Test', '').singularize.constantize
  end

end
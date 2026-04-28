require 'test_helper'
require 'helpers/tagable_policy_test'
module Electrical
  class DemandPolicyTest < ActiveSupport::TestCase
    include TagablePolicyTest

    # Deviates from the tagable policy setup for resources.
    # Demands are created with a demandable (Motor, LightCct, etc.) that has a tag.
    def setup
      # Set up projects and disciplines for in and out of current project scope tests,
      # and core users with roles
      setup_projects_and_users # In test/helpers/test_setup_helpers.rb
      # Setup in and out of scope disciplines on the resource module (Electrical).
      setup_disciplines(required_role: :designer)
      # Set up accredited users for electrical disciplines in each project
      setup_accredited_users(:designer)
      # Dummy alternate_discipline and alternate_accredited_user to pass irrelevant test in abstracted tests
      @alternate_discipline = create(:discipline, project: @project, name: "Test", 
        swatch: @swatch, required_role: :designer)
      @alternate_accredited_user = @accredited_user
      # Set up tags in and out of scope for testing
      setup_tags
      # Set up demandables, default is light_cct
      @demandable = create(:electrical_light_cct, tag: @tag)
      @other_demandable = create(:electrical_light_cct, tag: @other_tag)
      # Set up demands
      @resource = create(:electrical_demand, demandable: @demandable)
      @other_resource = create(:electrical_demand, demandable: @other_demandable)
    end

    def new_resource(discipline)
      # Uses demand factory to build new demand with tag association, using default prefix and unique serial.
      build(:electrical_demand, demandable: create(:electrical_motor, tag: create(:tag, :unique_tag, discipline: discipline)))
    end

    # Override: For demands, tag is on demandable, not demand itself
    undef test_resource_setup_is_valid
    test "resource setup is valid" do
      assert @tag.valid?
      assert @tag.persisted?
      assert @other_tag.valid?
      assert @other_tag.persisted?
      assert @resource.valid?
      assert @resource.persisted?
      assert @other_resource.valid?
      assert @other_resource.persisted?
      # Demand's tag is via demandable, not directly
      assert_equal @tag, @demandable.tag
      assert_equal @other_tag, @other_demandable.tag
      assert_equal @demandable, @resource.demandable
      assert_equal @other_demandable, @other_resource.demandable
    end

    # All remaining setup and tests have been abstracted to TagablePolicyTest and PolicyTestHelpers.
  end
end
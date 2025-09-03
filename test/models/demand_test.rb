require "test_helper"

class DemandTest < ActiveSupport::TestCase
  setup do
    project = create(:project)
    discipline = create(:discipline, code: 'E', name: 'Electrical')
    tag = create(:tag, :unique_tag, project: project, discipline: discipline, prefix: 'EL')
    @light_cct = create(:light_cct, tag: tag)
  end

  # Test validations
  test "should require basis" do
    demand = build(:demand, basis: nil, demandable: @light_cct)
    assert_not demand.valid?, "Demand should not be valid without basis. Errors: #{demand.errors.full_messages}"
    assert_includes demand.errors[:basis], "can't be blank"
  end

  test "should require config" do
    demand = build(:demand, config: nil, demandable: @light_cct)
    assert_not demand.valid?
    assert_includes demand.errors[:config], "can't be blank"
  end

  test "should validate power factor range" do
    demand = build(:demand, :power_pf_basis, power_factor: -1.1, demandable: @light_cct)
    assert_not demand.valid?, "Demand with power factor -1.1 should not be valid. Errors: #{demand.errors.full_messages}"
    
    demand.power_factor = 1.1
    assert_not demand.valid?, "Demand with power factor 1.1 should not be valid. Errors: #{demand.errors.full_messages}"
    
    demand.power_factor = 0.8
    assert demand.valid?, "Demand with power factor 0.8 should be valid. Errors: #{demand.errors.full_messages}"
  end

  test "should validate power factor not zero" do
    demand = build(:demand, :power_pf_basis, power_factor: 0.0, demandable: @light_cct)
    assert_not demand.valid?, "Demand with power factor 0.0 should not be valid. Errors: #{demand.errors.full_messages}"
    assert_includes demand.errors[:power_factor], "Power factor of zero will cause calculation errors"
  end

  test "should validate duty range" do
    demand = build(:demand, :power_pf_basis, duty: -0.1, demandable: @light_cct)
    assert_not demand.valid?, "Demand with duty -0.1 should not be valid. Errors: #{demand.errors.full_messages}"
    
    demand.duty = 1.1
    assert_not demand.valid?, "Demand with duty 1.1 should not be valid. Errors: #{demand.errors.full_messages}"
    
    demand.duty = 0.5
    assert demand.valid?, "Demand with duty 0.5 should be valid. Errors: #{demand.errors.full_messages}"
  end

  test "non-standard supply should override blank" do
    demand = build(:demand, :power_pf_basis, supply: "", other_supply: "250.0", demandable: @light_cct)
    assert demand.valid?, "Demand with other_supply should be valid. Errors: #{demand.errors.full_messages}"
    assert_equal 250.0, demand.supply
  end

  # Test delegated type functionality
  test "should be associated with demandable" do
    demand = build(:demand, demandable: @light_cct)
    assert demand.valid?, "Demand should be valid with demandable. Errors: #{demand.errors.full_messages}"
    assert_equal @light_cct, demand.demandable
  end

  test "should be able to access demandable through demand" do
    demand = create(:demand, demandable: @light_cct)
    assert_equal @light_cct, demand.demandable
  end

  # Test that the Demandable concern is working
  test "demandable should have demand association" do
    # First, remove any existing demand to avoid conflicts
    @light_cct.demand&.destroy
    
    # Create a demand with specific attributes for testing
    demand = create(:demand, 
      demandable: @light_cct,
      basis: 'current_pf',
      basis_notes: 'Test basis notes 7',
      supply: 220.0,
      config: 'two_120',
      current: 50.0,
      duty: 0.7
    )
    
    # Reload to ensure associations are set
    @light_cct.reload
    
    # Check the demand association by comparing attributes
    assert_equal demand.id, @light_cct.demand.id
    assert_equal @light_cct.id, @light_cct.demand.demandable.id
    assert_equal 'current_pf', @light_cct.demand.basis
    assert_equal 50.0, @light_cct.demand.current
  end

  # Test that the demand is destroyed when demandable is destroyed
  test "should require demandable to have a tag" do
    # Create a project and discipline for the tag
    project = create(:project)
    discipline = Discipline.find_or_create_by(code: 'E')
    
    # Create a tag without a tagable
    tag = create(:tag, :unique_tag,
      project: project,
      discipline: discipline,
      prefix: 'EL',
      description: 'Test Light Circuit'
    )
    
    # Create a light_cct with a tag first
    demandable = create(:light_cct, tag: tag)
    
    # Remove the tag association directly in the database
    tag.update_columns(tagable_id: nil, tagable_type: nil)
    
    # Create a demand with this demandable
    demand = build(:demand, demandable: demandable.reload)
    
    # Should not be valid because demandable has no tag
    assert_not demand.valid?, "Demand should not be valid with demandable without a tag"
    assert_includes demand.errors[:base], "Demandable must have a tag"
    
    # Now assign the tag and it should be valid
    tag.update_columns(tagable_id: demandable.id, tagable_type: 'LightCct')
    demandable.reload
    assert demand.valid?, "Demand should be valid when demandable has a tag"
    assert_difference 'Demand.count', 1 do
      demand.save!
    end
  end

  test "should destroy demand when demandable is destroyed" do
    # Create required associations
    project = create(:project)
    discipline = create(:discipline, code: 'M', name: 'Mechanical')
    
    # Create a new light_cct with a unique tag
    light_cct = create(:light_cct, 
      light_fitting_type: 'standard',
      quantity: 4,
      tag_attributes: {
        prefix: 'EL',
        serial: 9998,  # Ensure this is unique
        description: 'TEST DESTROY DEMAND',
        project: project,
        discipline: discipline,
        stage: 1
      }
    )
    
    # Create a demand for this light_cct using the association
    demand = light_cct.create_demand!(
      basis: 'power_pf',
      config: 'three_3c',
      basis_notes: 'Test basis notes',
      supply: 400.0,
      power: 1000.0
    )
    
    # Verify the demand was created and associated
    assert_not_nil light_cct.demand, "LightCct should have a demand"
    assert_equal demand.id, light_cct.demand.id, "Demand should be associated with light_cct"
    
    # Get the current demand count
    demand_count_before = Demand.count
    
    # Verify the demand exists in the database
    assert Demand.exists?(demand.id), "Demand should exist before destruction"
    
    # Store the demand ID for verification
    demand_id = demand.id
    
    # Destroy the light_cct
    light_cct.destroy
    
    # Verify the demand was destroyed
    demand_count_after = Demand.count
    assert_equal demand_count_before - 1, demand_count_after, 
      "Demand count should decrease by 1 after destroy"
    
    # Verify the specific demand was destroyed
    refute Demand.exists?(demand_id), "Demand with id #{demand_id} should no longer exist"
  end
end

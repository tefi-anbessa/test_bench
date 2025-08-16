require "test_helper"

class LoadTest < ActiveSupport::TestCase
  # Test validations
  test "should require basis" do
    load = build(:load, basis: nil)
    assert_not load.valid?, "Load should not be valid without basis. Errors: #{load.errors.full_messages}"
    assert_includes load.errors[:basis], "can't be blank"
  end

  test "should require config" do
    load = build(:load, config: nil)
    assert_not load.valid?
    assert_includes load.errors[:config], "can't be blank"
  end

  test "should validate power factor range" do
    load = build(:load, :power_pf_basis, power_factor: -1.1)
    assert_not load.valid?, "Load with power factor -1.1 should not be valid. Errors: #{load.errors.full_messages}"
    
    load.power_factor = 1.1
    assert_not load.valid?, "Load with power factor 1.1 should not be valid. Errors: #{load.errors.full_messages}"
    
    load.power_factor = 0.8
    assert load.valid?, "Load with power factor 0.8 should be valid. Errors: #{load.errors.full_messages}"
  end

  test "should validate power factor not zero" do
    load = build(:load, :power_pf_basis, power_factor: 0.0)
    assert_not load.valid?, "Load with power factor 0.0 should not be valid. Errors: #{load.errors.full_messages}"
    assert_includes load.errors[:power_factor], "Power factor of zero will cause calculation errors"
  end

  test "should validate duty range" do
    load = build(:load, :power_pf_basis, duty: -0.1)
    assert_not load.valid?, "Load with duty -0.1 should not be valid. Errors: #{load.errors.full_messages}"
    
    load.duty = 1.1
    assert_not load.valid?, "Load with duty 1.1 should not be valid. Errors: #{load.errors.full_messages}"
    
    load.duty = 0.5
    assert load.valid?, "Load with duty 0.5 should be valid. Errors: #{load.errors.full_messages}"
  end

  test "non-standard supply should override blank" do
    load = build(:load, :power_pf_basis, supply: "", other_supply: "250.0")
    assert load.valid?, "Load with other_supply should be valid. Errors: #{load.errors.full_messages}"
    assert_equal 250.0, load.supply
  end

  test "supply should be positive" do
    load = build(:load, :power_pf_basis, supply: 0.0)
    assert_not load.valid?, "Load with supply 0.0 should not be valid. Errors: #{load.errors.full_messages}"
    
    load.supply = -240.0
    assert_not load.valid?, "Load with supply -240.0 should not be valid. Errors: #{load.errors.full_messages}"
    
    load.supply = 240.0
    assert load.valid?, "Load with supply 240.0 should be valid. Errors: #{load.errors.full_messages}"
  end

  # Test each basis type
  test "power_pf basis calculations" do
    # Test with factory defaults first to ensure the factory produces valid loads
    load = build(:load, :power_pf_basis)
    assert load.valid?, "Load should be valid with factory defaults. Errors: #{load.errors.full_messages}"
    
    # Save to trigger calculations
    load.save
    
    # For power factor basis, vector should be power / power_factor
    expected_vector = load.power / load.power_factor
    # Current should be power / (supply * power_factor * number of conductors)
    # Note: The square root of 3 is already accounted for in the supply voltage
    expected_current = load.power / (load.supply * load.power_factor * load.conductor_count)
    
    # Verify calculations
    assert_in_delta expected_vector, load.vector, 0.01,
                   "Vector calculation failed. Expected power(#{load.power}) / power_factor(#{load.power_factor}) = #{expected_vector}, got #{load.vector}"
    
    assert_in_delta expected_current, load.current, 0.01,
                   "Current calculation failed. Expected #{load.power} / (#{load.supply} * #{load.power_factor} * #{load.conductor_count}) = #{expected_current}, got #{load.current}"
    
    # Test with specific test cases for different configurations
    test_cases = [
      # Single phase
      { config: :one, supply: 230.0, power: 1000.0, power_factor: 0.8 },
      # Three phase - supply is line-to-line voltage, no need for sqrt(3) in calculation
      { config: :three_3c, supply: 400.0, power: 5000.0, power_factor: 0.9 },
      # Two phase
      { config: :two_180, supply: 240.0, power: 2000.0, power_factor: 0.75 }
    ]
    
    test_cases.each do |test_case|
      load = build(:load, :power_pf_basis, test_case)
      assert load.valid?, "Load should be valid with #{test_case}. Errors: #{load.errors.full_messages}"
      
      # Save to trigger calculations
      load.save
      
      # Calculate expected values
      expected_vector = test_case[:power] / test_case[:power_factor]
      
      # Determine number of current-carrying conductors
      conductors = case test_case[:config].to_s
                  when 'one', 'dc' then 1
                  when 'two_120', 'two_180' then 2
                  when 'three_3c', 'three_4c' then 3
                  else 1
                  end
      
      # Calculate expected current
      # Note: The supply voltage is already the correct value (line-to-line for multi-phase)
      # so we don't need to apply sqrt(3) here
      expected_current = test_case[:power] / (test_case[:supply] * test_case[:power_factor] * conductors)
      
      # Verify calculations with descriptive error messages
      assert_in_delta expected_vector, load.vector, 0.01,
                     "Vector calculation failed for #{test_case[:config]}. " \
                     "Expected #{test_case[:power]} / #{test_case[:power_factor]} = #{expected_vector}, got #{load.vector}"
      
      assert_in_delta expected_current, load.current, 0.01,
                     "Current calculation failed for #{test_case[:config]}. " \
                     "Expected #{test_case[:power]} / (#{test_case[:supply]} * #{test_case[:power_factor]} * #{conductors}) = #{expected_current}, got #{load.current}"
    end
  end

  test "vector_pf basis calculations" do
    load = build(:load, :vector_pf_basis,
                vector: 2000.0,  # VA
                power_factor: 0.9,
                supply: 230.0,
                config: 'one')
    
    assert load.valid?
    load.save
    expected_current = 2000.0 / 230.0
    assert_in_delta expected_current, load.current, 0.01
    assert_equal 2000.0 * 0.9, load.power
  end

  test "current_pf basis calculations" do
    load = build(:load, :current_pf_basis,
                current: 10.0,  # A
                power_factor: 0.8,
                supply: 230.0,
                config: 'one')
    
    assert load.valid?
    load.save
    expected_power = 10.0 * 230.0 * 0.8
    assert_equal expected_power, load.power
    assert_equal load.power / 0.8, load.vector
  end

  test "current_power basis calculations" do
    load = build(:load, :current_power_basis,
                current: 10.0,  # A
                power: 2000.0,  # W
                supply: 230.0,
                config: 'one')
    
    assert load.valid?
    load.save
    assert_equal 10.0 * 230.0, load.vector
    assert_in_delta 2000.0 / (10.0 * 230.0), load.power_factor, 0.001
  end

  test "summation basis validations" do
    load = build(:load, :summation_basis, supply: 230.0, config: 'one')
    assert load.valid?
    assert_nil load.current
    assert_nil load.power
    assert_nil load.power_factor
    assert_nil load.vector
  end

  test "should handle missing data gracefully" do
    # Missing power for power_pf basis
    load = build(:load, :power_pf_basis, power: nil, supply: 230.0, config: 'one')
    assert load.valid?  # Valid because we don't validate presence of these
    assert_nil load.current
    assert_nil load.vector
  end

  test "factory traits should be valid" do
    assert build(:load, :power_pf_basis, supply: 230.0, config: 'one').valid?
    assert build(:load, :vector_pf_basis, supply: 230.0, config: 'one').valid?
    assert build(:load, :current_pf_basis, supply: 230.0, config: 'one').valid?
    assert build(:load, :current_power_basis, supply: 230.0, config: 'one').valid?
    assert build(:load, :summation_basis, supply: 230.0, config: 'one').valid?
  end

  test "load calculator should work" do
    load = build(:load, :power_pf_basis,
                power: 1000.0,
                power_factor: 0.8,
                supply: 230.0,
                config: 'one')
    
    assert load.valid?
    load.save
    expected_current = 1000.0 / (230.0 * 0.8)
    assert_in_delta expected_current, load.current, 0.01
    assert_equal 1000.0 / 0.8, load.vector
  end
end

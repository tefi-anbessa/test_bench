# frozen_string_literal: true

require "test_helper"
require 'helpers/tagable_model_tests'

module Electrical
  class HeaterTest < ActiveSupport::TestCase
    include TagableModelTests

    def setup
      setup_common_test_data
      @resource.electrical_demand = create(:electrical_demand, demandable: @resource)
    end

    test_required_fields(:heater_type, :application)
    test_enum_field(:heater_type, keys: [:heater_type_other,
                                          :cast_in,
                                          :ceramic_fiber,
                                          :circulation,
                                          :drum,
                                          :duct,
                                          :enclosure,
                                          :explosion_proof,
                                          :flexible,
                                          :forced_air,
                                          :heat_torch,
                                          :heat_tracing,
                                          :heating_cable,
                                          :immersion,
                                          :induction,
                                          :inline,
                                          :over_the_side,
                                          :radiant,
                                          :radiant_flat_panel,
                                          :radiant_reflective,
                                          :radiant_floor,
                                          :space,
                                          :strip,
                                          :tubular,
                                          :water])
    test_enum_field(:application, keys: [:application_other,
                                          :annealing_heat_treating,
                                          :curing_tempering,
                                          :drying,
                                          :melting,
                                          :oem_custom,
                                          :gases_vapors,
                                          :clean_water,
                                          :process_waters,
                                          :high_purity_waters,
                                          :lightweight_oils,
                                          :heavy_weight_oils,
                                          :medium_weight_oils,
                                          :mild_corrosive,
                                          :severe_corrosive,
                                          :caustic_solutions,
                                          :liquid_paraffin])
    test_enum_field(:sheath_material, prefix: true, keys: [:sheath_material_other,
                                          :sheath_material_none,
                                          :aluminium,
                                          :brass,
                                          :copper,
                                          :fluoropolymer,
                                          :ht_foil,
                                          :iron,
                                          :nickel_alloy,
                                          :polyimide,
                                          :rubber,
                                          :stainless_steel,
                                          :steel,
                                          :synthetic_rubber])
    test_enum_field(:insulation_material, prefix: true, keys: [:insulation_material_other, :no_insulation, :ceramic, :magnesium_oxide, :mica, :mineral, :fluoropolymer, :fiberglass])
    
  end
end
# frozen_string_literal: true

require "test_helper"
module Instrument
  class CableTypeDetailTest < ActiveSupport::TestCase
    def setup
      @project = create(:project, title: "Instrument::CableTypeDetail Model Test")
      @discipline = @project.disciplines.find_by(code: "J")
      @cable_type = create(:instrument_cable_type, discipline: @discipline)
      @resource = @cable_type.detail
    end

    test "factory builds a valid detail via the owning cable_type" do
      assert @resource.valid?
      assert @resource.persisted?
    end

    test "delegates discipline, label and long_label to its cable_type" do
      assert_equal @cable_type.discipline, @resource.discipline
      assert_equal @cable_type.label, @resource.label
      assert_equal @cable_type.long_label, @resource.long_label
    end

    test "destroying the cable_type destroys the detail" do
      detail_id = @resource.id
      @cable_type.destroy
      refute Instrument::CableTypeDetail.exists?(detail_id)
    end

    test "individual_screen, overall_screen and twist_pitch are independently settable" do
      @resource.update!(individual_screen: false, overall_screen: true, twist_pitch: 40.0)
      @resource.reload
      refute @resource.individual_screen
      assert @resource.overall_screen
      assert_equal 40.0, @resource.twist_pitch
    end
  end
end

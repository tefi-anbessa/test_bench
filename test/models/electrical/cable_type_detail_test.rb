# frozen_string_literal: true

require "test_helper"
module Electrical
  class CableTypeDetailTest < ActiveSupport::TestCase
    def setup
      @project = create(:project, title: "Electrical::CableTypeDetail Model Test")
      @discipline = @project.disciplines.find_by(code: "E")
      @cable_type = create(:electrical_cable_type, discipline: @discipline)
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
      refute Electrical::CableTypeDetail.exists?(detail_id)
    end

    test "neutral_csa and earth_csa are independently settable" do
      @resource.update!(neutral_csa: 4.0, earth_csa: 2.5)
      assert_equal 4.0, @resource.reload.neutral_csa
      assert_equal 2.5, @resource.earth_csa
    end
  end
end

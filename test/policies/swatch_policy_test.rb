# frozen_string_literal: true
require 'test_helper'
require 'helpers/test_setup_helpers'
  class SwatchPolicyTest < ActiveSupport::TestCase
    include TestSetupHelpers

    def setup
      setup_projects_and_users
      @swatch = create(:swatch, name: "policy_test")
    end

    test "scope should return all swatches" do
      assert_equal Swatch.all, SwatchPolicy::Scope.new(user_context(@app_owner, @project), Swatch).resolve
      assert_equal Swatch.all, SwatchPolicy::Scope.new(user_context(@admin, @project), Swatch).resolve
      assert_equal Swatch.all, SwatchPolicy::Scope.new(user_context(@regular_user, @project), Swatch).resolve
    end

    test "regular user can access index" do
      assert SwatchPolicy.new(user_context(@regular_user, @project), @swatch).index?
    end

    test "regular user can access show" do
      assert SwatchPolicy.new(user_context(@regular_user, @project), @swatch).show?
    end

    test "regular user cannot access new" do
      refute SwatchPolicy.new(user_context(@regular_user, @project), @swatch).new?
    end

    test "admin and app owner can access new" do
      assert SwatchPolicy.new(user_context(@admin, @project), @swatch).new?
      assert SwatchPolicy.new(user_context(@app_owner, @project), @swatch).new?
    end

    test "regular user cannot create" do
      refute SwatchPolicy.new(user_context(@regular_user, @project), @swatch).create?
    end

    test "admin and app owner can create" do
      assert SwatchPolicy.new(user_context(@admin, @project), @swatch).create?
      assert SwatchPolicy.new(user_context(@app_owner, @project), @swatch).create?
    end

    test "regular user cannot access edit" do
      refute SwatchPolicy.new(user_context(@regular_user, @project), @swatch).edit?
    end

    test "admin and app owner can access edit" do
      assert SwatchPolicy.new(user_context(@admin, @project), @swatch).edit?
      assert SwatchPolicy.new(user_context(@app_owner, @project), @swatch).edit?
    end

    test "regular user cannot update" do
      refute SwatchPolicy.new(user_context(@regular_user, @project), @swatch).update?
    end

    test "admin and app owner can update" do
      assert SwatchPolicy.new(user_context(@admin, @project), @swatch).update?
      assert SwatchPolicy.new(user_context(@app_owner, @project), @swatch).update?
    end

    test "admins and regular user cannot delete" do
      refute SwatchPolicy.new(user_context(@regular_user, @project), @swatch).destroy?
      refute SwatchPolicy.new(user_context(@admin, @project), @swatch).destroy?
    end

    test "app owner can delete" do
      assert SwatchPolicy.new(user_context(@app_owner, @project), @swatch).destroy?
    end
  end
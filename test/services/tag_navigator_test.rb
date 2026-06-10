require "test_helper"
require "helpers/test_setup_helpers"
class TagNavigatorTest < ActiveSupport::TestCase
  include TestSetupHelpers
  def setup
    setup_projects
    
    @discipline_e = @project.disciplines.find_by(code:'E')
    @discipline_j = @project.disciplines.find_by(code:'J')
    @other_discipline_e = @other_project.disciplines.find_by(code:'E')
    @other_discipline_j = @other_project.disciplines.find_by(code:'J')

    # Tests rely on sort_order for these disciplines being e before j.
    @discipline_e.update(sort_order: 1)
    @discipline_j.update(sort_order: 2)
    @other_discipline_e.update(sort_order: 1)
    @other_discipline_j.update(sort_order: 2)
    @discipline_e.reload
    @discipline_j.reload
    @other_discipline_e.reload
    @other_discipline_j.reload

    # normal ordering (full_tag)
    @e1 = create(:tag, discipline: @discipline_e, prefix: "A", serial: 1)
    @e2 = create(:tag, discipline: @discipline_e, prefix: "A", serial: 2)
    @e3 = create(:tag, discipline: @discipline_e, prefix: "B", serial: 1)

    # ISA51 ordering (loop_id) Sort order is i1, i2, i4, i3
    @i1  = create(:tag, discipline: @discipline_j, prefix: "BA", serial: 1)
    @i2  = create(:tag, discipline: @discipline_j, prefix: "BA", serial: 2)
    @i3  = create(:tag, discipline: @discipline_j, prefix: "BA", serial: 3)
    @i4  = create(:tag, discipline: @discipline_j, prefix: "BB", serial: 2)

    # normal ordering (full_tag)
    @other_e1 = create(:tag, discipline: @other_discipline_e, prefix: "A", serial: 1)
    @other_e2 = create(:tag, discipline: @other_discipline_e, prefix: "A", serial: 2)
    @other_e3 = create(:tag, discipline: @other_discipline_e, prefix: "B", serial: 1)

    # ISA51 ordering (loop_id) Sort order is i1, i2, i4, i3
    @other_i1  = create(:tag, discipline: @other_discipline_j, prefix: "BA", serial: 1)
    @other_i2  = create(:tag, discipline: @other_discipline_j, prefix: "BA", serial: 2)
    @other_i3  = create(:tag, discipline: @other_discipline_j, prefix: "BA", serial: 3)
    @other_i4  = create(:tag, discipline: @other_discipline_j, prefix: "BB", serial: 2)

    @scope = Tag.joins(discipline: :project)
  end

  def navigator(record)
    Navigator.new(
      scope: @scope,
      record: record
    )
  end

  test "setup is valid" do
    assert @project.persisted?
    assert @other_project.persisted?
    assert @other_project.code > @project.code
    assert @discipline_e.sort_order < @discipline_j.sort_order
    assert @other_discipline_e.sort_order < @other_discipline_j.sort_order
    assert @e1.valid?
    assert @e2.valid?
    assert @e3.valid?
    assert @i1.valid?
    assert @i2.valid?
    assert @i3.valid?
    assert @i4.valid?
    sql = @scope.to_sql
    assert_includes sql, 'JOIN "disciplines"'
    assert_includes sql, 'JOIN "projects"'
  end

  test "returns correct previous and next tags for normal ordering" do
    nav = navigator(@e2)

    prev, nxt = nav.neighbours

    assert_equal @e1.id, prev.id
    assert_equal @e3.id, nxt.id
  end

  test "returns correct previous and next tags for isa51 ordering" do
    nav = navigator(@i2)

    prev, nxt = nav.neighbours
    assert_equal @i1.id, prev.id
    assert_equal @i4.id, nxt.id
  end

  test "returns correct previous and next tags when crossing discipline boundaries" do
    nav = navigator(@e3)

    prev, nxt = nav.neighbours
    assert_equal @e2.id, prev.id
    assert_equal @i1.id, nxt.id

    nav = navigator(@i1)

    prev, nxt = nav.neighbours
    assert_equal @e3.id, prev.id
    assert_equal @i2.id, nxt.id
  end

  test "returns correct previous and next tags when crossing project boundaries" do
    nav = navigator(@other_e1)

    prev, nxt = nav.neighbours
    # This test exposes a kink in the sequence: crossing from isa51 sequence to regular
    assert_equal @i3.id, prev.id
    assert_equal @other_e2.id, nxt.id

    nav = navigator(@i3)

    prev, nxt = nav.neighbours
    assert_equal @i4.id, prev.id
    assert_equal @other_e1.id, nxt.id
  end

  test "returns nil at the ends of the list" do
    nav = navigator(@e1)

    prev, nxt = nav.neighbours
    assert_nil prev
    assert_equal @e2.id, nxt.id

    nav = navigator(@other_i3)

    prev, nxt = nav.neighbours
    assert_equal @other_i4.id, prev.id
    assert_nil nxt
  end
end
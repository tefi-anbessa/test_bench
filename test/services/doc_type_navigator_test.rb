require "test_helper"
require "helpers/test_setup_helpers"
class DocTypeNavigatorTest < ActiveSupport::TestCase
  include TestSetupHelpers
  def setup
    setup_projects
    
    @discipline_e = @project.disciplines.find_by(code:'E')
    @discipline_j = @project.disciplines.find_by(code:'J')
    @other_discipline_e = @other_project.disciplines.find_by(code:'E')

    @e1 = create(:doc_type, discipline: @discipline_e, code: 'A')
    @e2 = create(:doc_type, discipline: @discipline_e, code: 'B')
    @e3 = create(:doc_type, discipline: @discipline_e, code: 'C')
    @i1 = create(:doc_type, discipline: @discipline_j, code: 'A')
    @i2 = create(:doc_type, discipline: @discipline_j, code: 'B')
    @other_e1 = create(:doc_type, discipline: @other_discipline_e, code: 'A')

    # Tests rely on sort_order for these disciplines being e before j.
    @discipline_e.update(sort_order: 1)
    @discipline_j.update(sort_order: 2)
    @other_discipline_e.update(sort_order: 1)
    @discipline_e.reload
    @discipline_j.reload
    @other_discipline_e.reload

    @scope = DocType.joins(:discipline, :project)
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
    assert @e1.valid?
    assert @e2.valid?
    assert @i1.valid?
    assert @i2.valid?
    assert @other_e1.valid?
    sql = @scope.to_sql
    assert_includes sql, 'JOIN "disciplines"'
    assert_includes sql, 'JOIN "projects"'
  end

  test "returns correct previous and next for normal ordering" do
    nav = navigator(@e2)

    prev, nxt = nav.neighbours

    assert_equal @e1.id, prev.id
    assert_equal @e3.id, nxt.id
  end

  test "returns correct previous and next when crossing discipline boundaries" do
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
    assert_equal @i2.id, prev.id
    assert_nil nxt

    nav = navigator(@i2)

    prev, nxt = nav.neighbours
    assert_equal @i1.id, prev.id
    assert_equal @other_e1.id, nxt.id
  end

  test "returns nil at the ends of the list" do
    nav = navigator(@e1)

    prev, nxt = nav.neighbours
    assert_nil prev
    assert_equal @e2.id, nxt.id

    nav = navigator(@other_e1)

    prev, nxt = nav.neighbours
    assert_equal @i2.id, prev.id
    assert_nil nxt
  end
end
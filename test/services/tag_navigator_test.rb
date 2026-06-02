require "test_helper"

class TagNavigatorTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)

    @discipline_e = @project.disciplines.find_by(code:'E')
    @discipline_j = @project.disciplines.find_by(code:'J')

    # Tests rely on sort_order for these disciplines being e before j.
    @discipline_e.update(sort_order: 1)
    @discipline_j.update(sort_order: 2)
    @discipline_e.reload
    @discipline_j.reload

    # normal ordering (full_tag)
    @e1 = create(:tag, discipline: @discipline_e, prefix: "A", serial: 1)
    @e2 = create(:tag, discipline: @discipline_e, prefix: "A", serial: 2)
    @e3 = create(:tag, discipline: @discipline_e, prefix: "B", serial: 1)

    # ISA51 ordering (loop_id)
    @i1  = create(:tag, discipline: @discipline_j, prefix: "BA", serial: 1)
    @i2  = create(:tag, discipline: @discipline_j, prefix: "BA", serial: 2)
    @i3  = create(:tag, discipline: @discipline_j, prefix: "BA", serial: 3)
    @i4  = create(:tag, discipline: @discipline_j, prefix: "BB", serial: 2)

    @scope = Tag.joins(:discipline).where(disciplines: { project_id: @project.id }).includes(:discipline)
  end

  def navigator(record)
    Navigator.new(
      scope: @scope,
      record: record
    )
  end

  test "setup is valid" do
    assert @project.persisted?
    assert @discipline_e.sort_order < @discipline_j.sort_order
    assert @e1.valid?
    assert @e2.valid?
    assert @e3.valid?
    assert @i1.valid?
    assert @i2.valid?
    assert @i3.valid?
    assert @i4.valid?
    assert @scope.joins_values.include?(:discipline)
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
    puts "i2 loop_id: #{@i2.loop_id}; full_tag: #{@i2.full_tag}"
    puts "prev: loop_id: #{prev.loop_id}; full_tag: #{prev.full_tag}"
    puts "nxt: loop_id: #{nxt.loop_id}; full_tag: #{nxt.full_tag}"
    puts "i4 loop_id: #{@i4.loop_id}"
    puts "i2 schema: #{@i2.discipline.prefix_schema['name']}"
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
end
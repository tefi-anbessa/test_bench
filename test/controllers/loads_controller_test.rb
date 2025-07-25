require "test_helper"

class LoadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:valid)
    @tag = Tag.create(prefix: "PM",
                    serial: 11,
                    suffix: "B",
                    description: "Sump pump motor",
                    project: projects(:aa),
                    phase: 0,
                    notes: "yadda",
                    discipline: disciplines(:e),
                    tagable_type: Load
                  )
    @load = @tag.build_tagable(basis: 2,
                      basis_notes: "power and pf provided",
                      supply: 240.0,
                      config: "three_4c",
                      power: 1500.0,
                      power_factor: 0.6,
                      duty: 0.1)
  end

  test "no access unless logged in" do
    get loads_url
    assert_redirected_to new_user_session_url
    assert_not flash.empty?
  end

  test "should get index" do
    get loads_url
    assert_response :success
  end

  test "should get new" do
    get new_tag_load_url(@tag)
    assert_response :success
  end

  test "should create load" do
    assert_difference("Load.count") do
      post tag_loads_url(@tag), params: { load: {
                                            basis: @load.basis,
                                            basis_notes: @load.basis_notes,
                                            current: @load.current,
                                            duty: @load.duty,
                                            config: @load.config,
                                            power: @load.power,
                                            power_factor: @load.power_factor,
                                            supply: @load.supply,
                                            vector: @load.vector } }
    end
    assert_redirected_to load_url(Load.last)
  end

  test "should show load" do
    get load_url(loads(:pm))
    assert_response :success
  end

  test "should get edit" do
    get edit_load_url(loads(:pm))
    assert_response :success
  end

  test "should update load" do
    patch load_url(loads(:pm)), params: { load: {basis: @load.basis,
                                          basis_notes: @load.basis_notes,
                                          current: @load.current,
                                          duty: @load.duty,
                                          config: @load.config,
                                          power: @load.power,
                                          power_factor: @load.power_factor,
                                          supply: @load.supply,
                                          vector: @load.vector } }
    assert_redirected_to load_url(loads(:pm))
  end

  test "should destroy load" do
    @load.save
    assert_difference("Load.count", -1) do
      delete load_url(@load)
    end
    assert_redirected_to loads_url
  end
end

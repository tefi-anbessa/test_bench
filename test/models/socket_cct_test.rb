require "test_helper"

class SocketCctTest < ActiveSupport::TestCase

  def setup
    @tag = tags(:es)
    @socket_cct = socket_ccts(:es)
    @load = loads(:es)
  end

  test "fixtures should be valid" do
    socket_ccts.each do |t|
      assert t.valid?, t.errors.full_messages.inspect
    end
  end

  test "setup should be valid" do
    assert @tag.valid?
    assert @socket_cct.valid?
    assert_equal @tag.tagable, @socket_cct
  end

  test "create socket circuit as tagable linked to existing tag and link load" do
    @es_new = Tag.create(prefix: "ES",
                    serial: 99,
                    suffix: "",
                    description: "RECEPTION SOCKETS",
                    project: projects(:ab),
                    stage: 1,
                    notes: "SOCKET TEST",
                    discipline: disciplines(:e)
                  )
    assert @es_new.valid?
    assert @es_new.persisted?
    assert_difference 'SocketCct.count', 1 do
      @es_new.update(tagable: SocketCct.new(
                  socket_type: "universal",
                  quantity: 8
                  )
                )
      end
    assert_equal @es_new.tagable, @es_new.socket_cct
    assert_difference 'Load.count', 1 do
      @es_new.socket_cct.create_load(
                    basis: 4,
                    basis_notes: "current and pf provided",
                    supply: 240.0,
                    config: "one",
                    current: 10.0,
                    power_factor: 1.0,
                    duty: 0.1)
    end
  end

  test "destroy socket circuit should nullify tagable" do
    @socket_cct.destroy
    @tag.reload
    assert_nil @tag.tagable
  end

  test "destroy socket circuit should destroy load" do
    assert_difference 'Load.count', -1 do
      @socket_cct.destroy
    end
  end

  test "destroy tag should destroy socket circuit" do
    assert_difference 'SocketCct.count', -1 do
      @tag.destroy
    end
  end

end

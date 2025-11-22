require "test_helper"

class SocketCctTest < ActiveSupport::TestCase
  def setup
    @project = create(:project)
    @discipline = create(:discipline, project: @project, code: :elec)
    @tag = create(:tag, 
                 prefix: 'ES',
                 serial: 1,
                 service: 'TEST SOCKETS',
                 discipline: @discipline
               )
    @socket_cct = create(:electrical_socket_cct, 
                        socket_type: '10A',
                        quantity: 8,
                        tag: @tag
                       )
  end

  test "setup should be valid" do
    assert @project.valid?
    assert @discipline.valid?
    assert_equal @tag.discipline, @discipline
    assert @tag.valid?
    assert_equal @tag.project, @project
    assert @socket_cct.valid?
    assert_equal @socket_cct.tag, @tag
    assert_equal @tag.tagable, @socket_cct
  end

  test "factory should create socket circuit with valid attributes" do
    socket = build(:electrical_socket_cct)
    assert socket.valid?
  end

  test "socket circuit label should be tag label" do
    assert_equal @socket_cct.label, @tag.label
    assert_equal @socket_cct.long_label, @tag.long_label
  end

  test "socket circuit type must be present" do
    @socket_cct.socket_type = nil
    refute @socket_cct.valid?
    assert_includes @socket_cct.errors[:socket_type], I18n.t("errors.messages.blank")
  end

  test "socket circuit quantity must be present" do
    @socket_cct.quantity = nil
    refute @socket_cct.valid?
    assert_includes @socket_cct.errors[:quantity], I18n.t("errors.messages.not_a_number")
  end

  test "socket circuit quantity must be greater than 0" do
    @socket_cct.quantity = 0
    refute @socket_cct.valid?
    assert_includes @socket_cct.errors[:quantity], I18n.t("errors.messages.greater_than", count: 0)
  end

  test "should create socket circuit as tagable linked to existing tag" do
    # Use a unique serial number to avoid conflicts
    serial = 9999  # Using a high number to avoid conflicts with other tests
    
    tag = create(:tag, 
                prefix: 'ES',
                serial: serial,
                service: 'RECEPTION SOCKETS',
                discipline: @discipline
              )
    
    assert_difference 'Electrical::SocketCct.count', 1 do
      socket = create(:electrical_socket_cct, 
                     socket_type: '15A',
                     quantity: 4,
                     tag: tag
                    )
      
      tag.reload
      assert_equal tag.tagable, socket
      assert_equal tag.electrical_socket_cct, socket
    end
  end

  # Demand creation is tested separately in Demand model tests

  test "destroy socket circuit should nullify tagable" do
    @socket_cct.destroy
    
    @tag.reload
    assert_nil @tag.tagable
    assert_nil @tag.tagable_type
    assert_nil @tag.tagable_id
  end

  # Demand destruction is tested separately in Demand model tests

  test "destroy tag should destroy socket circuit" do
    socket_id = @socket_cct.id
    assert_difference 'Electrical::SocketCct.count', -1 do
      @tag.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { Electrical::SocketCct.find(socket_id) }
  end
  
  test "should have demand through demandable concern" do
    assert_respond_to @socket_cct, :electrical_demand
  end
  
  test "should have tag through tagable concern" do
    assert_respond_to @socket_cct, :tag
    assert_equal @tag, @socket_cct.tag
  end
  
  test "should have socket_type attribute" do
    assert_respond_to @socket_cct, :socket_type
    assert_equal '10A', @socket_cct.socket_type
  end
end

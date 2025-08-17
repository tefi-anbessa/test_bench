require "test_helper"

class SocketCctTest < ActiveSupport::TestCase
  def setup
    @discipline = create(:discipline, code: 'E', name: 'Electrical')
    @project = create(:project)
    @tag = create(:tag, 
                 prefix: 'ES',
                 serial: 1,
                 description: 'TEST SOCKETS',
                 project: @project,
                 discipline: @discipline
               )
    @socket_cct = create(:socket_cct, 
                        socket_type: 'standard',
                        quantity: 8,
                        tag: @tag
                       )
  end

  test "factory should be valid" do
    assert @socket_cct.valid?
    assert @tag.valid?
    assert @socket_cct.demand.valid?
  end

  test "should create socket circuit with valid attributes" do
    socket = build(:socket_cct)
    assert socket.valid?
  end

  test "should create socket circuit as tagable linked to existing tag" do
    # Use a unique serial number to avoid conflicts
    serial = 9999  # Using a high number to avoid conflicts with other tests
    
    tag = create(:tag, 
                prefix: 'ES',
                serial: serial,
                description: 'RECEPTION SOCKETS',
                project: @project,
                discipline: @discipline
              )
    
    assert_difference 'SocketCct.count', 1 do
      socket = create(:socket_cct, 
                     socket_type: 'standard',
                     quantity: 4,
                     tag: tag
                    )
      
      tag.reload
      assert_equal tag.tagable, socket
      assert_equal tag.socket_cct, socket
    end
  end

  test "should create demand when creating socket circuit" do
    # Create a unique tag for this test to avoid conflicts
    unique_serial = 9999
    socket = create(:socket_cct, 
                   socket_type: 'universal',
                   quantity: 2,
                   tag_attributes: {
                     prefix: 'ES',
                     serial: unique_serial,
                     description: 'UNIQUE TEST SOCKET',
                     project: @project,
                     discipline: @discipline,
                     stage: 1  # Adding a valid stage (0-10)
                   }
                  )
    assert socket.demand.present?
    assert_equal socket, socket.demand.demandable
  end

  test "destroy socket circuit should nullify tagable" do
    socket_id = @socket_cct.id
    @socket_cct.destroy
    
    @tag.reload
    assert_nil @tag.tagable
    assert_nil @tag.tagable_type
    assert_nil @tag.tagable_id
  end

  test "destroy socket circuit should destroy demand" do
    demand = @socket_cct.demand
    assert_difference 'Demand.count', -1 do
      @socket_cct.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { demand.reload }
  end

  test "destroy tag should destroy socket circuit" do
    socket_id = @socket_cct.id
    assert_difference 'SocketCct.count', -1 do
      @tag.destroy
    end
    assert_raises(ActiveRecord::RecordNotFound) { SocketCct.find(socket_id) }
  end
  
  test "should have demand through demandable concern" do
    assert_respond_to @socket_cct, :demand
    assert_kind_of Demand, @socket_cct.demand
  end
  
  test "should have tag through tagable concern" do
    assert_respond_to @socket_cct, :tag
    assert_equal @tag, @socket_cct.tag
  end
  
  test "should have socket_type attribute" do
    assert_respond_to @socket_cct, :socket_type
    assert_equal 'standard', @socket_cct.socket_type
  end
end


# Create the "super_admin" user.
unless User.find_by(name: "app_owner").present?
  @app_owner = User.create(name:  "app_owner",
             email: "app_owner@test.com",
             password:              "foobar",
             password_confirmation: "foobar",
             confirmed_at: Time.zone.now)
  @app_owner.grant(:app_owner)
end

# Create the "admin" user.
unless User.find_by(name: "admin").present?
  @admin = User.create(name:  "admin",
             email: "admin@test.com",
             password:              "foobar",
             password_confirmation: "foobar",
             confirmed_at: Time.zone.now)
@admin.grant(:admin)
end

# Create a "electrical_designer" global user. Add team member role after project is seeded.
unless User.find_by(name: "electrical_designer").present?
  @electrical_designer = User.create!(name:  "electrical_designer",
             email: "electrical_designer@test.com",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             confirmed_at: Time.zone.now)
  @electrical_designer.grant(:electrical_designer)
end

# Create a "team_member" user. Create role after project is seeded.
unless User.find_by(name: "team_member").present?
  @team_member = User.create!(name:  "team_member",
             email: "team_member@test.com",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             confirmed_at: Time.zone.now)
end
=begin
# Generate a bunch of additional users.
unless User.count > 10
  10.times do |n|
    name  = Faker::Name.first_name
    email = "example-#{n+1}@test.com"
    password = "password"
    User.create!(name:  name,
                email: email,
                password:              password,
                password_confirmation: password,
                confirmed_at: Time.zone.now)
  end
end

=end


# Create standard disciplines if they don't exist
Discipline::DISCIPLINES.each do |disc|
  Discipline.find_or_create_by!(code: disc[:code]) do |d|
    d.name = disc[:name]
  end
end

# Projects
# Create a known project
@project = Project.find_or_create_by!(code: "AB") do |p|
  p.title = "Tatai Property"
  p.description = "Resort development in Anlong Vak, Tatai"
end

# Add project specific roles if new users have been added
if @electrical_designer.present?
  @electrical_designer.grant(:team_member, @project)
end

if @team_member.present?
  @team_member.grant(:team_member, @project)
end

# Create some random projects on first seeding
if Project.count < 5
  30.times do |n|
    c = Project.all.order(:code).last.code.succ
    t = Faker::Company.bs.titleize
    d = Faker::Lorem.paragraph(sentence_count: 2, supplemental: false,
                                random_sentences_to_add: 4)
    Project.create!(code: c,
                    title: t,
                    description: d)
  end
end

# Tags
@project = Project.find_by(code: "AB")

# Create tag B:B-0012
Tag.find_or_create_by!(
  prefix: "B",
  serial: 12,
  suffix: "",
  project: @project,
  discipline: Discipline.find_by!(code: "B")
) do |tag|
  tag.service = "Cabin 2"
  tag.stage = 0
end

# Create tag E:EX-0004
Tag.find_or_create_by!(
  prefix: "EX",
  serial: 4,
  suffix: "",
  project: @project,
  discipline: Discipline.find_by!(code: "E")
) do |tag|
  tag.service = "GATEHOUSE SWITCHBOARD"
  tag.stage = 0
end

# Create tag E:EC-0002
Tag.find_or_create_by!(
  prefix: "EC",
  serial: 2,
  suffix: "",
  project: @project,
  discipline: Discipline.find_by!(code: "E")
) do |tag|
  tag.service = "FEEDER TO GATEHOUSE SWITCHBOARD"
  tag.stage = 0
end

# Create some random tags
unless Tag.count > 10
  prefixes = %w[CC CE CJB CX FT FV HV LT LZ PG PRV PT PZ XV ME MP MV A B LD LE LH LS LW P S SP T US V]
  disciplines = %w[A B C E I J M P U]
  120.times do |n|
    project = Project.find((1..Project.count).to_a.sample)
    prefix = prefixes.sample
    serial = rand(1..250)
    suffix = ["", "A", "B", "i", "z"].sample
    discipline = Discipline.find_by!(code: disciplines.sample)
    
    Tag.find_or_create_by!(
      prefix: prefix,
      serial: serial,
      suffix: suffix,
      project: project,
      discipline: discipline
    ) do |tag|
      tag.service = Faker::Science.tool
      tag.stage = rand(0..3)
      tag.notes = Faker::Lorem.paragraph(sentence_count: 2)
    end
  end
end

# Cable types
if CableType.count < 5
  @ct1 = CableType.create!(project: @project, conductor_material: "Cu", conductor_makeup: "2C+E",
                         csa: 2.5)
  @ct2 = CableType.create!(project: @project, conductor_material: "Cu", conductor_makeup: "4C",
                         csa: 2.5)
  @ct3 = CableType.create!(project: @project, conductor_material: "Cu", conductor_makeup: "4C",
                         csa: 4.0)
  @ct4 = CableType.create!(project: @project, conductor_material: "Cu", conductor_makeup: "4C",
                         csa: 10.0)
  @ct5 = CableType.create!(project: @project, conductor_material: "Cu", conductor_makeup: "4C",
                         csa: 35.0)
  @ct6 = CableType.create!(project: @project, conductor_material: "Cu", conductor_makeup: "4C",
                         csa: 150.0)
end

# Switchboards
# project = Project.find_by(code: "AB")
# Build the tag E:EX-0002 first
@ex1 = Tag.find_or_create_by!(
  prefix: "EX",
  serial: 1,
  suffix: "",
  project: @project,
  discipline: Discipline.find_by!(code: "E")
) do |tag|
  tag.service = "POLE MOUNTED CIRCUIT BREAKER"
  tag.stage = 0
end

# If it is first pass, create the switchboard
if @ex1.tagable.nil?
  @ex1.tagable = Switchboard.create!(
    location: "Service pole",
    service: "Outdoor tropical environment",
    ingress_protection: "IP44",
    busbar_rating: 200.0,
    busbar_fault_rating: 5000.0,
    busbar_fault_duration: 0.5,
    cable_entry: "Bottom",
    incomer_protection: "MCCB 220A",
    metering: "",
    neutral_bar_connections: "1 x 90 mm2",
    earth_bar_connections: "2 x 150 mm2"
  )
  
  # Add a circuit
  1.times do |n|
    @ex1.switchboard.circuits.create!(
      serial: n + 1,
      notes: Faker::Lorem.paragraph(sentence_count: 2)
    )
  end
end

# Build the load next
if @ex1.tagable.demand.nil? 
  @ex1.tagable.demand = Demand.create!(
    basis: "summation", 
    supply: 240.0, 
    config: "three_4c"
  )
end
  
# Build the tag E:EX-0002 first
@ex2 = Tag.find_or_create_by!(
  prefix: "EX",
  serial: 2,
  suffix: "",
  project: @project,
  discipline: Discipline.find_by!(code: "E")
) do |tag|
  tag.service = "GATEHOUSE SWITCHBOARD"
  tag.stage = 0
end

# If it is first pass, create the switchboard
if @ex2.tagable.nil?
  @ex2.tagable = Switchboard.create!(
      location:                   "Gatehouse",
      service:                    "Indoor tropical environment",
      ingress_protection:         "IP22",
      busbar_rating:              200.0,
      busbar_fault_rating:        5000.0,
      busbar_fault_duration:      0.5,
      cable_entry:                "Bottom",
      incomer_protection:         "None",
      metering:                   "VOLTS (SWITCH TO ANY PHASE)",
      neutral_bar_connections:    "1 x 50 mm2, 1 X 35 mm2, 1 x 10 mm2, 2 x 150 mm2",
      earth_bar_connections:      "9 X 2.5 mm2, 6 X 4 mm2, 2 x 150 mm2"
  )
    # Add some circuits
    12.times do |n|
      @ex2.switchboard.circuits.create!(
      serial: n + 1
    )
  end
end

# Build the load next
if @ex2.tagable.demand.nil? 
  @ex2.tagable.demand = Demand.create!(
    basis: "summation", 
    supply: 80.0, 
    config: "three_4c"
  )
end

# Build the tag E:EX-0004 first
@ex4 = Tag.find_or_create_by!(
  prefix: "EX",
  serial: 4,
  suffix: "",
  project: @project,
  discipline: Discipline.find_by!(code: "E")
) do |tag|
  tag.service = "SOUTH AREA DISTRIBUTION BOARD"
  tag.stage = 1
end
# If it is first pass, create the switchboard
if @ex4.tagable.nil?
  @ex4.tagable = Switchboard.create!(
    location: "ADJACENT BUILDING B-0011",
    service: "OUTDOOR TROPICAL",
    ingress_protection: "IP44",
    busbar_rating: 63.0,
    busbar_fault_rating: 1000.0,
      busbar_fault_duration:      0.5,
      cable_entry:                "Bottom",
      incomer_protection:         "SURGE DIVERTER",
      metering:                   "NO",
      neutral_bar_connections:    "3 x 10 mm2, 2 x 35 mm2",
      earth_bar_connections:      "12 X 2.5 mm2, 2 x 35 mm2"
    )
    # Add some circuits
    16.times do |n|
      ex4.switchboard.circuits.create!(
        serial: n + 1
    )
  end
end
  
# Build the load next
if @ex4.tagable.demand.nil? 
  @ex4.tagable.demand = Demand.create!(
    basis: "summation", 
    supply: 63.0, 
    config: "three_4c"
  )
end

# More Loads

# Build the tag E:PM-0021 first
@pm = Tag.find_or_create_by!(
  prefix: "PM", 
  serial: 21, 
  suffix: "",
  project: @project,
  service: "DISTRIBUTION PUMP MOTOR",
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)

# Build the tagable motor next
if @pm.tagable.nil?
  @pm.tagable = Motor.create(
    motor_type: "Single phase",
    frame_size: "16",
    poles: 1,
    ingress_protection: "IP44",
    speed_rated: 500.0 
  )
end
# Build the load next
if @pm.tagable.demand.nil? 
  @pm.tagable.demand = Demand.create!(basis: "power_pf", supply: 240.0, config: "three_3c",
                              power: 500.0, power_factor: 0.6, duty: 0.1)
end

# Build the tag E:ES-0021 first
@es = Tag.find_or_create_by!(
  prefix: "ES", 
  serial: 21, 
  suffix: "",
  project: @project,
  service: "GATEHOUSE SOCKET OUTLETS",
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)
# Build the tagable socket_cct next
if @es.tagable.nil?
  @es.tagable = SocketCct.create(
    socket_type: "Single phase",
    quantity: 5
  )
end

# Build the load next
if @es.tagable.demand.nil?
  @es.tagable.demand = Demand.create!(
    basis: "current_pf", 
    supply: 240.0, 
    config: "one",
    current: 10.0, 
    power_factor: 1.0, 
    duty: 0.1
  )
end

# Build the tag E:EL-0031 first
@el = Tag.find_or_create_by!(
  prefix: "EL", 
  serial: 31, 
  suffix: "",
  project: @project,
  service: "GATEHOUSE LIGHTING",
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)
# Build the tagable light_cct next
if el.tagable.nil?
  el.tagable = LightCct.create(
    light_fitting_type: "Ceiling mount bayonet",
    quantity: 5
  )
end

# Build the load next
if @el.tagable.demand.nil?
  @el.tagable.demand = Demand.create!(
    basis: "power_pf", 
    supply: 240.0, 
    config: "one",
    power: 100.0, 
    power_factor: 0.98, 
    duty: 0.5
  )
end

# Cables
# Build the tag E:EC-0001 first
ec1 = Tag.find_or_create_by!(
  prefix: "EC", 
  serial: 1, 
  suffix: "",
  project: @project,
  service: 'GATEHOUSE SWITCHBOARD FEEDER',
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)

# Build the tagable cable next
if ec1.tagable.nil?
  ec1.tagable = Cable.create!(cable_type: ct5)
end

# Build the tag E:EC-0002 first
@ec2 = project.tags.find_or_create_by!(
  prefix: "EC", 
  serial: 2, 
  suffix: "",
  service: 'SOUTH AREA DISTRIBUTION BOARD FEEDER',
  project: @project,
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)
# Build the tagable cable next
if ec2.tagable.nil?
  ec2.tagable = Cable.create!(cable_type: ct4)
end

# Build the tag E:EC-0003
@ec3 = Tag.find_or_create_by!(
  prefix: "EC", 
  serial: 3, 
  suffix: "",
  service: 'UPS #1 WIRING',
  project: @project,
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)
# Build the tagable cable next
if @ec3.tagable.nil?
  @ec3.tagable = Cable.create!(cable_type: @ct1)
end

# Build the tag E:EC-0004 first
@ec4 = Tag.find_or_create_by!(
  prefix: "EC", 
  serial: 4, 
  suffix: "",
  service: 'DISTRIBUTION PUMP MOTOR FEEDER',
  project: @project,
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)
# Build the tagable cable next
if @ec4.tagable.nil?
  @ec4.tagable = Cable.create!(cable_type: ct2)
end

# Build the tag E:EC-0005 first
@ec5 = Tag.find_or_create_by!(
  prefix: "EC", 
  serial: 5, 
  suffix: "",
  service: 'GATEHOUSE SOCKET OUTLETS WIRING',
  project: @project,
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)
# Build the tagable cable next
if @ec5.tagable.nil?
  @ec5.tagable = Cable.create!(cable_type: ct2)
end

# Build the tag E:EC-0006 first
@ec6 = Tag.find_or_create_by!(
  prefix: "EC", 
  serial: 6, 
  suffix: "",
  service: 'GATEHOUSE LIGHTING WIRING',
  project: @project,
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
)
# Build the tagable cable next
if @ec6.tagable.nil?
  @ec6.tagable = Cable.create!(cable_type: @ct1)
end

unless Cable.count > 50 
  # Build 50 tagged cables
  tag_params = {
  prefix: "EC", 
  suffix: "",
  project: @project,
  stage: 1,
  discipline: Discipline.find_by!(code: "E")
  }
  cable_params = {
    cable_type: @ct1
  }
  50.times do |i|
    n = i+101
    tag_params[:serial] = n
    tag_params[:service] = "TEST CABLE #{n}"
    @tag = Tag.create!(tag_params.merge(tagable: Cable.new(cable_params)))
  end
end
=begin
# Create a main sample user.
unless User.find_by(name: "owner").present?
  u = User.new(name:  "owner",
             email: "a@b.c",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             confirmed_at: Time.zone.now)
end

# Generate a bunch of additional users.
unless User.count > 10
  10.times do |n|
    name  = Faker::Name.first_name
    email = "example-#{n+1}@b.c"
    password = "password"
    User.create!(name:  name,
                email: email,
                password:              password,
                password_confirmation: password,
                confirmed_at: Time.zone.now)
  end
end

=end

# Roles
if owner = User.find_by(name: "owner")
  owner.grant :owner
end

# Create standard disciplines if they don't exist
Discipline::DISCIPLINES.each do |disc|
  Discipline.find_or_create_by!(code: disc[:code]) do |d|
    d.name = disc[:name]
  end
end

# Projects
unless Project.find_by(code: "AB").present?
  Project.create!(code: "AB", title: "Tatai Property", description:
    "Resort development in Anlong Vak, Tatai")
end

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
project = Project.find_by(code: "AB")
unless Tag.find_by(prefix: "B", serial: 12, suffix: "").present?
  project.tags.create!(prefix: "B",
              serial: 12,
              description: "Cabin 2",
              phase: 0,
              discipline_id: Discipline.find_by(code: "B").id)
end
unless Tag.count > 10
  prefixes = "CC,CE,CJB,CX,FT,FV,HV,LT,LZ,PG,PRV,PT,PZ,XV,ME,MP,MV,A,B,LD,LE,LH,LS,LW,P,S,SP,T,US,V"
  disciplines = "A,B,C,E,I,J,M,P,U"
  120.times do |n|
    project = Project.find((1..Project.count).to_a.sample)
    project.tags.create!(prefix: prefixes.split(",").sample,
                serial: rand(1..250),
                suffix: ["", "A", "B", "i", "z"].sample,
                description: Faker::Science.tool,
                phase: rand(0..3),
                discipline_id: Discipline.find_by(code: disciplines.split(",").sample).id,
                notes: Faker::Lorem.paragraph(sentence_count: 2))
  end
end

# Cable types
if CableType.count < 5
  ct1 = CableType.create(conductor_material: "Cu", conductor_makeup: "2C+E",
                        csa: 2.5)
  ct2 = CableType.create(conductor_material: "Cu", conductor_makeup: "4C",
                        csa: 2.5)
  ct3 = CableType.create(conductor_material: "Cu", conductor_makeup: "4C",
                        csa: 4.0)
  ct4 = CableType.create(conductor_material: "Cu", conductor_makeup: "4C",
                        csa: 10.0)
  ct5 = CableType.create(conductor_material: "Cu", conductor_makeup: "4C",
                        csa: 35.0)
  ct6 = CableType.create(conductor_material: "Cu", conductor_makeup: "4C",
                        csa: 150.0)
end

# Switchboards
project = Project.find_by(code: "AB")
ex1 = Tag.find_or_create_by!(prefix: "EX", serial: 1, suffix: "",
                                      project_id: project.id,
                                      phase: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
ex1.update(description: "POLE MOUNTED CIRCUIT BREAKER")

ex2 = Tag.find_or_create_by!(prefix: "EX", serial: 2, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ex2.update(description: "GATEHOUSE SWITCHBOARD")
if ex2.tagable.nil?
  ex2.tagable = Switchboard.create!(
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
end

ex4 = Tag.find_or_create_by!(prefix: "EX", serial: 4, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ex4.update(description: "SOUTH AREA DISTRIBUTION BOARD")
if ex4.tagable.nil?
  ex4.tagable = Switchboard.create!(
      location:                   "ADJACENT BUILDING B-0011",
      service:                    "OUTDOOR TROPICAL",
      ingress_protection:         "IP44",
      busbar_rating:              63.0,
      busbar_fault_rating:        1000.0,
      busbar_fault_duration:      0.5,
      cable_entry:                "Bottom",
      incomer_protection:         "SURGE DIVERTER",
      metering:                   "NO",
      neutral_bar_connections:    "3 x 10 mm2, 2 x 35 mm2",
      earth_bar_connections:      "12 X 2.5 mm2, 2 x 35 mm2"
    )
  ex4.tagable = Load.create!(basis: "summation", supply: 240.0, phase: "three_4c")
end
# Some loads
ee2 = Tag.find_or_create_by!(prefix: "EE", serial: 2, suffix: "",
                                      project_id: project.id,
                                      phase: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
ee2.update(description: 'UPS #1')
if ee2.load.nil?
  ee2_load = ee2.create_load(basis: "power_pf", supply: 240.0, config: "one",
                              power: 500, power_factor: 0.6, duty: 0.5)
end
pm = Tag.find_or_create_by!(prefix: "PM", serial: 21, suffix: "",
                                      project_id: project.id,
                                      config: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
pm.update(description: "DISTRIBUTION PUMP MOTOR")
if pm.load.nil?
  pm_load = pm.create_load(basis: "power_pf", supply: 240.0, config: "three_3c",
                              power: 500.0, power_factor: 0.6, duty: 0.1)
end
es = Tag.find_or_create_by!(prefix: "ES", serial: 21, suffix: "",
                                      project_id: project.id,
                                      config: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
es.update(description: "GATEHOUSE SOCKET OUTLETS")
if es.load.nil?
  es_load = es.create_load(basis: "current_pf", supply: 240.0, config: "one",
                              current: 10.0, power_factor: 1.0, duty: 0.1)
end
el = Tag.find_or_create_by!(prefix: "EL", serial: 31, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
el.update(description: "GATEHOUSE LIGHTING")
if el.load.nil?
  el_load = el.create_load(basis: "power_pf", supply: 240.0, config: "one",
                              power: 50.0, power_factor: 1.0, duty: 0.1)
end

# Cables
ec1 = Tag.find_or_create_by!(prefix: "EC", serial: 1, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec1.update(description: 'GATEHOUSE SWITCHBOARD FEEDER')
if ec1.tagable.nil?
  ec1.tagable = Cable.create!(cable_type: ct5)
end
ec2 = project.tags.find_or_create_by!(prefix: "EC", serial: 2, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec2.update(description: 'SOUTH AREA DISTRIBUTION BOARD FEEDER')
if ec2.tagable.nil?
  ec2.tagable = Cable.create!(cable_type: ct4)
end
ec3 = Tag.find_or_create_by!(prefix: "EC", serial: 3, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec3.update(description: 'UPS #1 WIRING')
if ec3.tagable.nil?
  ec3.tagable = Cable.create!(cable_type: ct1)
end
ec4 = Tag.find_or_create_by!(prefix: "EC", serial: 4, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec4.update(description: 'DISTRIBUTION PUMP MOTOR FEEDER')
if ec4.tagable.nil?
  ec4.tagable = Cable.create!(cable_type: ct2)
end
ec5 = Tag.find_or_create_by!(prefix: "EC", serial: 5, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec5.update(description: 'GATEHOUSE SOCKET OUTLETS WIRING')
if ec5.tagable.nil?
  ec5.tagable = Cable.create!(cable_type: ct2)
end
ec6 = project.tags.find_or_create_by!(prefix: "EC", serial: 6, suffix: "",
                                      project_id: project.id,
                                      phase: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec6.update(description: 'GATEHOUSE LIGHTING WIRING')
if ec6.tagable.nil?
  ec6.tagable = Cable.create!(cable_type: ct1)
end

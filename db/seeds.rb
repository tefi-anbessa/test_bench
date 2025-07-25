#=begin
# Create a main sample user.
unless User.find_by(name: "owner").present?
  User.create(name:  "owner",
             email: "owner@test_bench.org",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             confirmed_at: Time.zone.now)
end

# Generate a bunch of additional users.
unless User.count > 10
  10.times do |n|
    name  = Faker::Name.first_name
    email = "example-#{n+1}@test_bench.org"
    password = "password"
    User.create!(name:  name,
                email: email,
                password:              password,
                password_confirmation: password,
                confirmed_at: Time.zone.now)
  end
end

# Roles
if owner = User.find_by(name: "owner")
  owner.grant :owner
end

# Disciplines
if Discipline.count < 5
  Discipline.create!(code: 'A', name: 'Administration')
  Discipline.create!(code: 'B', name: 'Architecture')
  Discipline.create!(code: 'C', name: 'Civil Engineering')
  Discipline.create!(code: 'E', name: 'Electrical Engineering')
  Discipline.create!(code: 'I', name: 'Information Tech')
  Discipline.create!(code: 'J', name: 'Instrument Engineering')
  Discipline.create!(code: 'M', name: 'Mechanical Engineering')
  Discipline.create!(code: 'P', name: 'Process Engineering')
  Discipline.create!(code: 'U', name: 'Multi-Discipline')
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
                        csa: 4.0)
  ct3 = CableType.create(conductor_material: "Cu", conductor_makeup: "4C",
                        csa: 10.0)
  ct4 = CableType.create(conductor_material: "Cu", conductor_makeup: "4C",
                        csa: 35.0)
  ct5 = CableType.create(conductor_material: "Cu", conductor_makeup: "4C",
                        csa: 150.0)
end

# Loads
ex1 = Tag.find_or_create_by!(prefix: "EX", serial: 1, suffix: "",
                                      project_id: project.id,
                                      config: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
ex1.update(description: "POLE MOUNTED CIRCUIT BREAKER")
if ex1.tagable.nil?
  ex1.tagable = Load.create!(basis: "summation", supply: 240.0, phase: "three_4c")
end
ex2 = Tag.find_or_create_by!(prefix: "EX", serial: 2, suffix: "",
                                      project_id: project.id,
                                      config: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ex2.update(description: "GATEHOUSE SWITCHBOARD")
if ex2.tagable.nil?
  ex2.tagable = Load.create!(basis: "summation", supply: 240.0, phase: "three_4c")
end
ex4 = Tag.find_or_create_by!(prefix: "EX", serial: 4, suffix: "",
                                      project_id: project.id,
                                      config: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
ex4.update(description: "SOUTH AREA DISTRIBUTION BOARD")
if ex4.tagable.nil?
  ex4.tagable = Load.create!(basis: "summation", supply: 240.0, phase: "three_4c")
end
ee2 = Tag.find_or_create_by!(prefix: "EE", serial: 2, suffix: "",
                                      project_id: project.id,
                                      config: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
ee2.update(description: 'UPS #1')
if ee2.tagable.nil?
  ee2.tagable = Load.create!(basis: "power_pf", supply: 240.0, phase: "one",
                              power: 500, power_factor: 0.6, duty: 0.5)
end
pm = Tag.find_or_create_by!(prefix: "PM", serial: 21, suffix: "",
                                      project_id: project.id,
                                      config: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
pm.update(description: "DISTRIBUTION PUMP MOTOR")
if pm.tagable.nil?
  pm.tagable = Load.create!(basis: "power_pf", supply: 240.0, phase: "three_3c",
                              power: 500.0, power_factor: 0.6, duty: 0.1)
end
es = Tag.find_or_create_by!(prefix: "ES", serial: 21, suffix: "",
                                      project_id: project.id,
                                      config: 0,
                                      discipline_id: Discipline.find_by(code: "E").id)
es.update(description: "GATEHOUSE SOCKET OUTLETS")
if es.tagable.nil?
  es.tagable = Load.create!(basis: "current_pf", supply: 240.0, phase: "one",
                              current: 16.0, power_factor: 1.0, duty: 0.1)
end
el = Tag.find_or_create_by!(prefix: "EL", serial: 31, suffix: "",
                                      project_id: project.id,
                                      config: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
el.update(description: "GATEHOUSE LIGHTING")
if el.tagable.nil?
  el.tagable = Load.create!(basis: "current_pf", supply: 240.0, phase: "one",
                              current: 5.0, power_factor: 1.0, duty: 0.1)
end

# Cables
ec1 = Tag.find_or_create_by!(prefix: "EC", serial: 1, suffix: "",
                                      project_id: project.id,
                                      config: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec1.update(description: 'GATEHOUSE SWITCHBOARD FEEDER')
if ec1.tagable.nil?
  ec1.tagable = Cable.create!(cable_type: ct5,
                          feeder: ex1.load,
                          incomer: ex2.load)
end
ec2 = project.tags.find_or_create_by!(prefix: "EC", serial: 2, suffix: "",
                                      project_id: project.id,
                                      config: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec2.update(description: 'SOUTH AREA DISTRIBUTION BOARD FEEDER')
if ec2.tagable.nil?
  ec2.tagable = Cable.create!(cable_type: ct4,
                          feeder: ex2.load,
                          incomer: ex4.load)
end
ec3 = Tag.find_or_create_by!(prefix: "EC", serial: 3, suffix: "",
                                      project_id: project.id,
                                      config: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec3.update(description: 'UPS #1 WIRING')
if ec3.tagable.nil?
  ec3.tagable = Cable.create!(cable_type: ct1,
                          feeder: ex2.load,
                          incomer: ee2.load)
end
ec4 = Tag.find_or_create_by!(prefix: "EC", serial: 4, suffix: "",
                                      project_id: project.id,
                                      config: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec4.update(description: 'DISTRIBUTION PUMP MOTOR FEEDER')
if ec4.tagable.nil?
  ec4.tagable = Cable.create!(cable_type: ct2,
                          feeder: ex4.load,
                          incomer: pm.load)
end
ec5 = Tag.find_or_create_by!(prefix: "EC", serial: 5, suffix: "",
                                      project_id: project.id,
                                      config: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec5.update(description: 'GATEHOUSE SOCKET OUTLETS WIRING')
if ec5.tagable.nil?
  ec5.tagable = Cable.create!(cable_type: ct2,
                          feeder: ex2.load,
                          incomer: es.load)
end
ec6 = project.tags.find_or_create_by!(prefix: "EC", serial: 6, suffix: "",
                                      project_id: project.id,
                                      config: 1,
                                      discipline_id: Discipline.find_by(code: "E").id)
ec6.update(description: 'GATEHOUSE LIGHTING WIRING')
if ec6.tagable.nil?
  ec6.tagable = Cable.create!(cable_type: ct1,
                          feeder: ex2.load,
                          incomer: el.load)
end

#=end

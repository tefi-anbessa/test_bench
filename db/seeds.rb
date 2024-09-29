#=begin
# Create a main sample user.
unless User.find_by(name: "example").present?
  User.create(name:  "example",
             email: "example@railstutorial.org",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             confirmed_at: Time.zone.now)
end

# Generate a bunch of additional users.
unless User.count > 10
  10.times do |n|
    name  = Faker::Name.first_name
    email = "example-#{n+1}@railstutorial.org"
    password = "password"
    User.create!(name:  name,
                email: email,
                password:              password,
                password_confirmation: password,
                confirmed_at: Time.zone.now)
  end
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
unless Project.find_by(code: "AA").present?
  Project.create!(code: "AA", title: "Kampot Investigation", description:
    "Looking for development opportunity in Kampot.")
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
if Tag.count == 0
  project = Project.first
  project.tags.create!(prefix: "B",
              serial: 12,
              description: "Cabin 2",
              phase: 0,
              discipline_id: Discipline.find_by(code: "B").id)
end
unless Tag.count > 10
  prefixes = "CC,CE,CJB,CX,EC,EE,EL,EX,FT,FV,HV,LT,LZ,PG,PRV,PT,PZ,XV,ME,MP,MV,A,B,LD,LE,LH,LS,LW,P,S,SP,T,US,V"
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
#=end

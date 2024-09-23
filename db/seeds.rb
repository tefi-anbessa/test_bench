=begin
# Create a main sample user.
User.create!(name:  "Example",
             email: "example@railstutorial.org",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             confirmed_at: Time.zone.now)

# Generate a bunch of additional users.
10.times do |n|
  name  = Faker::Name.first_name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  User.create!(name:  name,
              email: email,
              password:              password,
              password_confirmation: password,
              confirmed_at: Time.zone.now)


# Disciplines
Discipline.create!(code: 'A', name: 'Administration')
Discipline.create!(code: 'B', name: 'Architecture')
Discipline.create!(code: 'C', name: 'Civil Engineering')
Discipline.create!(code: 'E', name: 'Electrical Engineering')
Discipline.create!(code: 'I', name: 'Information Tech')
Discipline.create!(code: 'J', name: 'Instrument Engineering')
Discipline.create!(code: 'M', name: 'Mechanical Engineering')
Discipline.create!(code: 'P', name: 'Process Engineering')
Discipline.create!(code: 'U', name: 'Multi-Discipline')

30.times do |n|
  c = Project.all.order(:code).last.code.succ
  t = Faker::Company.bs.titleize
  d = Faker::Lorem.paragraph(sentence_count: 2, supplemental: false,
                              random_sentences_to_add: 4)
  Project.create!(code: c,
                  title: t,
                  description: d)
end
=end

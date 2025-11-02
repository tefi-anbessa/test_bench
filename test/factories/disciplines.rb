# test/factories/disciplines.rb
FactoryBot.define do

  factory :discipline do
    association :project, factory: :project
    code { "code#{SecureRandom.hex(4)}" }
    label { code.upcase }  # Default to code if not specified
    name { "Discipline #{code}" }
    module_name { name.parameterize.underscore.camelize }
    sort_order { 100 }
    prefix_schema { { schema: :default } }

    # Standard disciplines from Constants
    Constants.disciplines.each do |disc|
      trait(disc[:code]) do
        code { disc[:code].to_s }
        label { disc[:label] }
        name { disc[:name] }
        module_name { disc[:module] }
        sort_order { disc[:sort_order] }
        prefix_schema { disc[:prefix_schema] }
      end
    end
    # For specific discipline types
    trait :elec do
      code { :elec }
      label { "E" }
      name { 'Electrical' }
    end
    
    trait :mech do
      code { :mech }
      label { "M" }
      name { 'Mechanical' }
    end
    
    trait :inst do
      code { :inst }
      label { "J" }
      name { 'Instrumentation' }
    end
  end
end

def generate_unique_code(project)
  return 'A' unless project.present? && project.persisted?
  # Find the next available code for this project
  project_id = project&.id || Project.first&.id

  # Find all existing codes for this project
  existing_codes = project.disciplines.pluck(:code)

  # Find the next available code (fill gaps)
  ('A'..'Z').find { |c| !existing_codes.include?(c) } || 'Z'

end
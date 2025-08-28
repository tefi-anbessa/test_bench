# This factory creates discipline instances on demand
FactoryBot.define do
  factory :discipline do
    # Default to first discipline if no code/name specified
    code { Discipline::DISCIPLINES.first[:code] }
    name { Discipline::DISCIPLINES.first[:name] }

    # Create traits for each standard discipline
    Discipline::DISCIPLINES.each do |disc|
      trait disc[:code].downcase.to_sym do
        code { disc[:code] }
        name { disc[:name] }
      end
    end

    # Find or create the discipline in the database
    to_create do |instance|
      instance.class.find_or_create_by(code: instance.code) do |d|
        d.name = instance.name
      end
    end
  end
end

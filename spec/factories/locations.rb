FactoryGirl.define do
  factory :location do
    building   { 10+rand(36) }
    area       { FFaker::Lorem.characters(1).upcase }
    initialize_with do
      # pick random stockit location if exists, if not, create one (patch to work for demo data or spec run)
      Location.where("stockit_id IS NOT NULL").limit(1).order("RANDOM()").first ||
        Location.find_or_initialize_by(building: building, area: area)
    end

    trait :dispatched do
      building 'Dispatched'
    end
  end

end

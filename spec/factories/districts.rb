# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :district do
    sequence(:name_en) { |n| seq.keys.sort[n%seq.keys.size] }
    name_zh_tw         { seq[name_en][:name_zh_tw] }
    latitude           { seq[name_en][:latitude] }
    longitude          { seq[name_en][:longitude] }
    territory

    # Ensures FactoryBot.create(:object, attr1: 'xyz', attr2: 'abc') actually returns a record
    #   from the DB if exists whilst also applying our custom attributes
    # https://dev.to/jooeycheng/factorybot-findorcreateby-3h8k
    to_create do |instance|
      instance.id = District.where(name_en: instance.name_en).first_or_create(instance.attributes).id
      instance.instance_variable_set('@new_record', false) # could use reload instead
    end

    transient do
      seq { generate(:districts) }
    end

  end

  sequence :districts do |n|
    @districts ||= YAML.load_file("#{Rails.root}/db/districts.yml")
  end

end

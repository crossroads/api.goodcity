# frozen_String_literal: true

FactoryBot.define do
  factory :territory do
    sequence(:name_en) { |n| seq.keys.sort[n%seq.keys.size] }
    name_zh_tw         { seq[name_en][:name_zh_tw] }

    # Ensures FactoryBot.create(:object, attr1: 'xyz', attr2: 'abc') actually returns a record
    #   from the DB if exists whilst also applying our custom attributes
    # https://dev.to/jooeycheng/factorybot-findorcreateby-3h8k
    to_create do |instance|
      instance.id = Territory.where(name_en: instance.name_en).first_or_create(instance.attributes).id
      instance.instance_variable_set('@new_record', false)
    end

    transient do
      seq { @package_types ||= YAML.load_file("#{Rails.root}/db/territories.yml") }
    end

  end

end

FactoryBot.define do
  factory :process_checklist do

    text_en      { seq[1][:text_en] }
    text_zh_tw   { seq[1][:text_zh_tw] }
    booking_type { build(:booking_type, identifier: seq[0]) }
    initialize_with { ProcessChecklist.find_or_initialize_by(booking_type: booking_type, text_en: text_en) }

    transient do
      seq { generate(:process_checklists).first }
    end

    trait :online_order do
      booking_type { association :booking_type, :online_order }
    end

    trait :appointment do
      booking_type { association :booking_type, :appointment }
    end

  end

  # returns { "booking_type" => {text_en: 'xyz', text_zh_tw: 'xyz'}}
  sequence :process_checklists do |n|
    @process_checklists ||= YAML.load_file("#{Rails.root}/db/process_checklists.yml")
    items = []
    @process_checklists.each{|k,v| v.each{|i| items << {k => i}}} # flatten the list
    items[n%items.size]
  end

end

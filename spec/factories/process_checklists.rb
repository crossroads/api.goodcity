FactoryBot.define do
  factory :process_checklist do

    text_en      { process_checklist_item[1][:text_en] }
    text_zh_tw   { process_checklist_item[1][:text_zh_tw] }
    booking_type { create(:booking_type, identifier: process_checklist_item[0]) }
    initialize_with { ProcessChecklist.find_or_initialize_by(booking_type: booking_type, text_en: text_en) }

    trait :online_order do
      booking_type { create(:booking_type, :online_order) }
    end

    trait :appointment do
      booking_type { create(:booking_type, :appointment) }
    end

    transient do
      process_checklist_item { generate(:process_checklists).first }
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

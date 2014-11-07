namespace :goodcity do

  # rake goodcity:update_rejection_reasons
  desc 'Update Rejection Reasons'
  task update_rejection_reasons: :environment do

    rejection_reasons = YAML.load_file("#{Rails.root}/db/rejection_reasons.yml")
    rejection_reasons.each do |name_en, value|
      RejectionReason.where(
        name_en: name_en,
        name_zh_tw: value[:name_zh_tw]
      ).first_or_create
    end

    RejectionReason.find_by(name_en: 'Other').try(:destroy)
  end
end

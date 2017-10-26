namespace :goodcity do
  task assign_default_donor_condition: :environment do
    lightly_used = DonorCondition.find_by(name_en: 'Lightly Used')

    Package.where(donor_condition_id: nil).each do |package|
      package.donor_condition_id = lightly_used.id
      package.save
    end
  end
end

namespace :goodcity do

  # rake goodcity:add_holidays
  desc 'Add holidays list'
  task add_holidays: :environment do
    holidays = YAML.load_file("#{Rails.root}/db/holidays.yml")
    holidays.each do |_key, value|
      date_value = DateTime.parse(value[:holiday]).in_time_zone(Time.zone)
      Holiday.where(
        name: value[:name],
        year: value[:year],
        holiday: date_value
      ).first_or_create
    end
  end

end

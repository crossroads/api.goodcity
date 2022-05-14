FactoryBot.define do
  sequence :code do |n|
    "#{(65 + Random.rand(26)).chr}#{Random.rand(5)}"
  end

  sequence :inventory_number do |n|
    rand(1000000).to_s.rjust(6,'0')
  end

  sequence :package_types do |n|
    @package_types ||= YAML.load_file("#{Rails.root}/db/package_types.yml")
  end

  sequence :schedules do |n|
    @schedules ||= YAML.load_file("#{Rails.root}/db/schedules.yml")
  end

  sequence :roles do |n|
    @roles ||= YAML.load_file("#{Rails.root}/db/roles.yml")
  end

  sequence :permissions_roles do |n|
    roles = YAML.load_file("#{Rails.root}/db/permissions_roles.yml")
    roles.each_pair { |key, value| value.flatten! }
    @permissions_roles ||= roles
  end

  sequence :mobile do |n|
    "+852" << (%w(5 6 9).sample) << ("%07d" % n)
  end

  sequence :phone_number do |n|
    (1..8).map { rand(9) }.join
  end

end

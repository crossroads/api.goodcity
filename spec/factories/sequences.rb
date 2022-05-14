FactoryBot.define do
  sequence :delivered_by do
    ['Gogovan','Crossroads truck','Dropped off'].sample
  end

  sequence :code do |n|
    "#{(65 + Random.rand(26)).chr}#{Random.rand(5)}"
  end

  sequence :inventory_number do |n|
    rand(1000000).to_s.rjust(6,'0')
  end

  sequence :identity_types do |n|
    @identity_types ||= YAML.load_file("#{Rails.root}/db/identity_types.yml")
  end

  sequence :item_types do |n|
    @item_types ||= YAML.load_file("#{Rails.root}/db/item_types.yml")
  end

  sequence :package_types do |n|
    @package_types ||= YAML.load_file("#{Rails.root}/db/package_types.yml")
  end

  sequence :random_chinese_string do |n|
    %w( 蒏葝葮 賌輈鄍 毄滱漮歅 駓駗潣 譋轐鏕 厊圪妀 裌覅峬峿鋡鬵鵛嚪袀豇貣 珝砯砨慖 磏磑禠 獛獡獚弰捃吪吙餀 駽髾髽 倱哻圁蛶 鬖鰝鰨 浞浧浵 僄塓塕鵹鵿 衒袟狅妵妶 馻噈嫶鉾 覟魆魦魵 鍌鍗鍷鰩鷎 ).sample
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

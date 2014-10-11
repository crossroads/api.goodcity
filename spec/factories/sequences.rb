FactoryGirl.define do

  sequence :donor_conditions do |n|
    @donor_conditions ||= YAML.load_file("#{Rails.root}/db/donor_conditions.yml")
  end

  sequence :rejection_reasons do |n|
    @rejection_reasons ||= YAML.load_file("#{Rails.root}/db/rejection_reasons.yml")
  end

  sequence :districts do |n|
    @districts ||= YAML.load_file("#{Rails.root}/db/districts.yml")
  end

  sequence :territories do |n|
    @territories ||= YAML.load_file("#{Rails.root}/db/territories.yml")
  end

  sequence :item_types do |n|
    @item_types ||= YAML.load_file("#{Rails.root}/db/item_types.yml")
  end

  sequence :random_chinese_string do |n|
    %w( 蒏葝葮 賌輈鄍 毄滱漮歅 駓駗潣 譋轐鏕 厊圪妀 裌覅峬峿鋡鬵鵛嚪袀豇貣 珝砯砨慖 磏磑禠 獛獡獚弰捃吪吙餀 駽髾髽 倱哻圁蛶 鬖鰝鰨 浞浧浵 僄塓塕鵹鵿 衒袟狅妵妶 馻噈嫶鉾 覟魆魦魵 鍌鍗鍷鰩鷎 ).sample
  end

  sequence :schedules do |n|
    @schedules ||= YAML.load_file("#{Rails.root}/db/schedules.yml")
  end

  sequence :mobile do |n|
    "+852" << (%w(5 6 9).sample) << (1..7).map{rand(9)}.join
  end

end

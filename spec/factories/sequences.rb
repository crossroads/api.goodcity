FactoryGirl.define do

  sequence :donor_conditions do |n|
    @donor_conditions ||= YAML.load_file("#{Rails.root}/db/donor_conditions.yml")
  end

  sequence :code do |n|
    "#{(65 + Random.rand(26)).chr}#{Random.rand(5)}"
  end

  sequence :inventory_number do |n|
    rand(1000000).to_s.rjust(6,'0')
  end

  sequence :timeslots do |n|
    [["9AM-11AM", "上午9時至上午11時"], ["11AM-1PM", "午11時至下午1時"],
      ["2PM-4PM", "下午2時至下午4時"], ["4PM-6PM", "下午4時至下午6時"]].sample
  end

  sequence :rejection_reasons do |n|
    @rejection_reasons ||= YAML.load_file("#{Rails.root}/db/rejection_reasons.yml")
  end

  sequence :cancellation_reasons do |n|
    @cancellation_reasons ||= YAML.load_file("#{Rails.root}/db/cancellation_reasons.yml")
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

  sequence :package_types do |n|
    @package_types ||= YAML.load_file("#{Rails.root}/db/package_types.yml")
  end
  
  sequence :gogovan_transports do |n|
    @gogovan_options = YAML.load_file("#{Rails.root}/db/gogovan_transports.yml")
  end

  sequence :crossroads_transports do |n|
    @crossroads_options = YAML.load_file("#{Rails.root}/db/crossroads_transports.yml")
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

  sequence :cloudinary_image_id do |n|
    seq = %w(
      1416897663/szfmfbmjeq6aphyfflmg.jpg
      1416902230/mmguhm3zdkonc2nynjue.jpg
      1416229451/jgpyo4oxrnfnjriofdjd.jpg
      1416817641/auyhxsvppoohnubhtdvp.jpg
      1416375331/zppxdm5fljlyv3tcfo3p.jpg
      1415435713/i6lzfri9xpjzzznxgfnv.jpg
      1415379081/hbqmdhzk47524ppxw7xs.jpg
      1415015815/iijhzfxwjrkavecs8wjp.jpg
      1414914035/ijip6ea6kjy6zn4mz81q.jpg
      1414308170/kdc3pkmli7du4wcnyppz.jpg
    )
    i = n.modulo(seq.size)
    seq[i]
  end

end

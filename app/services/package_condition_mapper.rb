class PackageConditionMapper
  CONDITIONS_HASH = { "New" => 'N', "Lightly Used" => 'M', "Heavily Used" => 'U', "Broken" => 'B' }
  def self.to_stockit(condition)
    CONDITIONS_HASH[condition]
  end

  def self.to_condition(stockit)
    CONDITIONS_HASH.key(stockit)
  end
end

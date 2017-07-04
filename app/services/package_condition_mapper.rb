class PackageConditionMapper
  CONDITIONS_MAPPING = {
                          "New" => 'N',
                          "Lightly Used" => 'M',
                          "Heavily Used" => 'U',
                          "Broken" => 'B'
                        }

  def self.to_stockit(condition)
    CONDITIONS_MAPPING[condition]
  end

  def self.to_condition(stockit_condition_name)
    CONDITIONS_MAPPING.key(stockit_condition_name)
  end
end

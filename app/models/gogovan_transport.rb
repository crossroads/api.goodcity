class GogovanTransport < ActiveRecord::Base
  translates :name
  validates :name_en, presence: true

  def vehicle_tag
    case name_en
      when '5.5 Tonne Truck' then 'mudou'
      when 'Van' then 'van'
      when '9 Tonne Truck' then 'mudou9'
    end
  end

  def self.get_vehicle_tag(gogovanOptionId)
    find_by(id: gogovanOptionId).try(:vehicle_tag)
  end
end

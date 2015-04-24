class GogovanTransport < ActiveRecord::Base
  translates :name
  validates :name_en, presence: true

  def vehicle_tag
    case name_en
      when '5.5t Truck' then 'mudou'
      when 'Van' then 'van'
      end
  end
end

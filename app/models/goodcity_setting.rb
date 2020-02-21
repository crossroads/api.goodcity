class GoodcitySetting < ActiveRecord::Base
  validates :key, uniqueness: true, presence: true

  def self.enabled?(key)
    get(key).eql?("true")
  end

  def self.get(key, default: nil)
    GoodcitySetting.find_by(key: key)&.value || default
  end

  def self.get_date(key, default: nil)
    Date.parse GoodcitySetting.get(key)
  rescue
    default
  end
end

class GoodcitySetting < ActiveRecord::Base
  validates :key, uniqueness: true, presence: true

  def self.enabled?(key)
    find_by(key: key)&.value&.eql?("true")
  end
end

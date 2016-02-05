module GoodcitySync

  extend ActiveSupport::Concern

  def self.request_from_stockit
    RequestStore.store[:request_from_stockit] || false
  end

  def self.request_from_stockit=(value)
    RequestStore.store[:request_from_stockit] = value
  end

end

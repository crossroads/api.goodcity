module GoodcitySync

  extend ActiveSupport::Concern

  def self.request_from_stockit
    Thread.current[:request_from_stockit] || false
  end

  def self.request_from_stockit=(value)
    Thread.current[:request_from_stockit] = value
  end

end

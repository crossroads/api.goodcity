module GoodcitySync

  extend ActiveSupport::Concern

  included do
    before_action :set_request_from_stockit, only: [:update, :destroy, :create]
  end

  def self.request_from_stockit
    Thread.current[:request_from_stockit] || false
  end

  def self.request_from_stockit=(value)
    Thread.current[:request_from_stockit] = value
  end

  private

  def set_request_from_stockit
    GoodcitySync.request_from_stockit = false
  end

end

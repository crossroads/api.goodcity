module GoodcitySync

  extend ActiveSupport::Concern

  included do
    before_action :set_stockit_request, only: [:update, :destroy, :create]
  end

  def self.request_from_stockit
    Thread.current[:request_from_stockit] || false
  end

  def self.request_from_stockit=(value)
    Thread.current[:request_from_stockit] = value
  end

  private

  def set_stockit_request
    GoodcitySync.request_from_stockit = false
  end

end

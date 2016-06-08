require 'stockit/base'

module Stockit
  class LocalOrderSync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/local_orders")
      get(url)
    end

  end
end

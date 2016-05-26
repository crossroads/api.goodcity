require 'stockit/base'

module Stockit
  class PalletSync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/pallets")
      get(url)
    end

  end
end

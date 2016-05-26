require 'stockit/base'

module Stockit
  class BoxSync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/boxes")
      get(url)
    end

  end

end

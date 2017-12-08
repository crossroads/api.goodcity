require 'stockit/base'

module Stockit
  class LocationSync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/locations")
      get(url)
    end

  end
end

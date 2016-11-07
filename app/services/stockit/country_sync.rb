require 'stockit/base'

module Stockit
  class CountrySync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/countries")
      get(url)
    end

  end
end

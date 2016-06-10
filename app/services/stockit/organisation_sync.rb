require 'stockit/base'

module Stockit
  class OrganisationSync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/organisations")
      get(url)
    end

  end
end

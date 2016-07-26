require 'stockit/base'

module Stockit
  class DesignationSync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/designations")
      get(url, { designation: { detail_type: "LocalOrder" } })
    end

  end
end

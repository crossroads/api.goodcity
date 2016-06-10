require 'stockit/base'

module Stockit
  class ContactSync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/contacts")
      get(url)
    end

  end
end

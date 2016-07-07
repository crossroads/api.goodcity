require 'stockit/base'

module Stockit
  class ActivitySync

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/activities")
      get(url)
    end

  end
end

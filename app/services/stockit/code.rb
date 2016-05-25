require 'stockit/base'

module Stockit
  class Code

    include Stockit::Base

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/codes")
      get(url)
    end

  end

end

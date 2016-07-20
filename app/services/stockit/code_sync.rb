require 'stockit/base'

module Stockit
  class CodeSync

    include Stockit::Base

    attr_accessor :code

    def initialize(code = nil)
      @code = code
    end

    def self.index
      new.index
    end

    def self.create(code)
      new(code).create
    end

    def index
      url = url_for("/api/v1/codes")
      get(url)
    end

    def create
      url = url_for("/api/v1/codes")
      post(url, stockit_params)
    end

    private

    def stockit_params
      {
        code: {
          code: code.code,
          description_en: code.name_en,
          description_zht: code.name_zh_tw
        }
      }
    end

  end

end

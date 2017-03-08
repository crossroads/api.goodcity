require 'stockit/base'

module Stockit
  class CountrySync

    include Stockit::Base

    def initialize(country_name_en , country_name_zh , country_code, country_region)
      @name_en = country_name_en
      @name_zh = country_name_zh
      @code = country_code
      @region_en = country_region
    end

    def self.index
      new.index
    end

    def self.create(country_name_en, country_name_zh, country_code, country_region)
      new(country_name_en, country_name_zh, country_code, country_region).create
    end

    def index
      url = url_for("/api/v1/countries")
      get(url)
    end

    def create
      url = url_for("/api/v1/countries")
      stockit_params = {
        name_en: @name_en,
        name_zh: @name_zh,
        code: @code,
        region_en: @region_en
      }
      post(url, stockit_params)
    end
  end
end

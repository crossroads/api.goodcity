require 'stockit/base'

module Stockit
  class DesignationSync

    include Stockit::Base

    attr_accessor :designation

    def initialize(designation = nil)
      @designation = designation
    end

    def self.index
      new.index
    end

    def index
      url = url_for("/api/v1/designations")
      get(url)
    end

    def self.create(designation)
      new(designation).create
    end

    def create
      url = url_for("/api/v1/designations")
      post(url, stockit_params)
    end

    private

    def stockit_params
      {
        designation: {
          code: designation.code,
          detail_type: designation.detail_type
        }
      }
    end

  end
end

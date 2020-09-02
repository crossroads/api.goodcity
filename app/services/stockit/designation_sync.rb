require 'stockit/base'

module Stockit
  class DesignationSync

    include Stockit::Base

    attr_accessor :designation

    def initialize(designation = nil, params = {})
      @designation = designation
      @params = params
    end

    def self.index
      new.index
    end

    def index
      if @params.any?
        query_string = @params.map{|k,v| "#{k}=#{v}"}.join("&")
        url = url_for("/api/v1/designations?#{query_string}")
      else
        url = url_for("/api/v1/designations")
      end
      get(url)
    end

    def show
      url = url_for("/api/v1/designations/#{@params[:id]}")
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

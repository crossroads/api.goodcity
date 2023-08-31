module Api::V1
  class OrganisationNamesSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :name_en, :name_zh_tw, :description_en, :description_zh_tw, :registration,
      :website, :organisation_type_id, :district_id, :country_id, :created_at,
      :updated_at

    def include_description_en?
      @options[:include_description_en] != false
    end

    def include_description_zh_tw?
      @options[:include_description_zh_tw] != false
    end

    def include_registration?
      @options[:include_registration] != false
    end

    def include_website?
      @options[:include_website] != false
    end

    def include_organisation_type_id?
      @options[:include_organisation_type_id] != false
    end

    def include_district_id?
      @options[:include_district_id] != false
    end

    def include_country_id?
      @options[:include_country_id] != false
    end

  end
end

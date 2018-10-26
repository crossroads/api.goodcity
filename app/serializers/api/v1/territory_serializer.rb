module Api::V1
  class TerritorySerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name

    has_many :districts, serializer: DistrictSerializer

    def name__sql
      "name_#{current_language}"
    end

    # def initialize(object, options={})
    #   super(object, options)
    #   # create include_#{attribute}? methods for each
    #   byebug
    #   include_attributes = options[:include_attributes] || []
    #   include_attributes.each do |attr|
    #     self.class.define_include_method(attr)
    #   end
    #   exclude_attributes = options[:exclude_attributes] || []
    #   exclude_attributes.each do |attr|
    #     self.class.define_include_method(attr) # need to set to false
    #   end
    # end

    # def include_associations!
    #   byebug
    #   include! :districts if @options[:include_districts] == true
    # end

    # def include_districts?
    #   byebug
    #   @options[:include_districts] == true
    # end

    # def self.attributes
    #   hash = super
    #   byebug
    #   if @options[:include_districts] == true
    #     hash["districts"] = object.districts
    #   end
    #   hash
    # end

  end
end

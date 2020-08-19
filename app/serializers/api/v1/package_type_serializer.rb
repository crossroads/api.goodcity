module Api::V1
  class PackageTypeSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :code, :other_child_packages,
               :default_child_packages, :other_terms, :visible_in_selects,
               :allow_requests, :allow_pieces, :allow_expiry_date,
               :subform, :allow_box, :allow_pallet
    attribute "name_#{current_language}".to_sym

    has_one :location, serializer: LocationSerializer

    def include_attribute?
      User.current_user.present? && !@options[:exclude_code_details]
    end

    def other_terms
      object.try("other_terms_#{current_language}".to_sym) ||
        object.other_terms_en
    end

    def other_child_packages
      object.other_child_package_types.pluck(:code).join(',')
    end

    def default_child_packages
      object.default_child_package_types.pluck(:code).join(',')
    end

    alias include_other_child_packages? include_attribute?
    alias include_default_child_packages? include_attribute?
  end
end

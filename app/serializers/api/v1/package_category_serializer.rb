module Api::V1

  class PackageCategorySerializer < ApplicationSerializer
    # embed :ids, include: true
    attributes :id, :name, :parent_id

    def name__sql
      "name_#{current_language}"
    end
  end

end

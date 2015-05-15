module Api::V1

  class PackageTypeSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name, :code

    def name__sql
      "name_#{current_language}"
    end
  end

end

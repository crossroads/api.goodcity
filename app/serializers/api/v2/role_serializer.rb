module Api::V2
  class RoleSerializer
    include FastJsonapi::ObjectSerializer

    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id,
      :name,
      :level

  end
end
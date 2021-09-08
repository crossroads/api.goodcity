module Api::V2
  class RoleSerializer < GoodcitySerializer
    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :name, :level
  end
end

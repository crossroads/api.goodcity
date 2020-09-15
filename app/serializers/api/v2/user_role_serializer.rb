module Api::V2
  class UserRoleSerializer
    include FastJsonapi::ObjectSerializer

    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes  :created_at, :updated_at

    belongs_to :role
    belongs_to :user

  end
end
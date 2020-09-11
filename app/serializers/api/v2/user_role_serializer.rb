module Api::V2
  class UserRoleSerializer
    include FastJsonapi::ObjectSerializer

    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id,
      :user_id,
      :role_id,
      :created_at,
      :updated_at

    belongs_to :role
    belongs_to :user

  end
end
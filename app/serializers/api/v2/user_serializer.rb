module Api::V2
  class UserSerializer < GoodcitySerializer

    # ----------------------------
    #   Attributes
    # ----------------------------

    attributes :id,
      :first_name,
      :last_name,
      :mobile,
      :title,
      :created_at,
      :updated_at,
      :last_connected,
      :last_disconnected,
      :email,
      :is_email_verified,
      :is_mobile_verified,
      :disabled,
      :preferred_language

    # ----------------------------
    #   Relationships
    # ----------------------------

    has_many :roles
    
  end
end

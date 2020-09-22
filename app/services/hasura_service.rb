class HasuraService

  class << self
    PUBLIC_ROLE = 'public'
    BASE_ROLE   = 'user'

    def authenticate(user)
      allowed_roles = user_roles(user) + [BASE_ROLE, PUBLIC_ROLE]
      default_role  = allowed_roles.first

      Token.new(jwt_config: jwt_config).generate({
        "user_id":  user.id,
        "audience": jwt_config[:audience],
        "issuer":   jwt_config[:issuer],
        "https://hasura.io/jwt/claims": {
          "x-hasura-allowed-roles":           allowed_roles,
          "x-hasura-default-role":            default_role,
          "x-hasura-user-id":                 user.id.to_s,
          "x-hasura-organisation-ids":        to_postgres_array(user_organisations(user))
        }
      })
    end

    def user_roles(user)
      user.roles
        .order('level DESC')
        .map(&:snake_name)
        .uniq
    end

    def user_organisations(user)
      user.active_organisations.map(&:id).map(&:to_s)
    end

    def to_postgres_array(arr)
      "{" + arr.join(',') + "}"
    end

    def jwt_config
      Rails.application.secrets.hasura
    end
  end
end

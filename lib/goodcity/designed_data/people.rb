module Goodcity
  class DesignedData
    #
    # Synthetic people: staff, donors, charity users (each tied to a REAL organisation
    # from the reference data) and a name bank for beneficiaries. Nobody here is real.
    #
    # The two local test logins are created exactly as goodcity-local's
    # scripts/create-test-users.rb creates them, because the real-API smoke suite and
    # login scripts depend on them.
    #
    class People
      attr_reader :ctx

      def initialize(ctx, spec)
        @ctx = ctx
        @spec = spec
        @users = {}
        @beneficiary_n = 0
      end

      def build!
        since = ctx.time('-900d@09:00')

        @spec.fetch('test_users').each do |u|
          user = User.find_by(mobile: u['mobile']) || User.new(mobile: u['mobile'])
          user.assign_attributes(u.slice('first_name', 'last_name', 'email').merge('is_mobile_verified' => true))
          user.save!
          u['roles'].each { |name| UserRole.where(user: user, role: ctx.reference.role(name)).first_or_create! }
          @users[u['key']] = user
        end

        (@spec.fetch('staff') + @spec.fetch('donors') + @spec.fetch('charities')).each do |u|
          ctx.at(u['since'] || since) do
            user = User.create!(u.slice('title', 'first_name', 'last_name', 'mobile', 'email', 'preferred_language')
                                 .merge('is_mobile_verified' => true, 'receive_email' => false))
            (u['roles'] || []).each { |name| UserRole.create!(user: user, role: ctx.reference.role(name)) }
            if u['organisation']
              OrganisationsUser.create!(user: user, organisation: ctx.reference.organisation(u['organisation']),
                                        position: u['position'], status: u['status'] || 'approved',
                                        preferred_contact_number: u['mobile'])
            end
            @users[u['key']] = user
          end
        end
        self
      end

      def user(key)
        @users[key.to_s] || raise(ArgumentError, "no person with key #{key.inspect} in people.yml")
      end

      def keys(group)
        @spec.fetch(group).map { |u| u['key'] }
      end

      def staff_with(role)
        @spec.fetch('staff').select { |u| (u['roles'] || []).include?(role) }.map { |u| user(u['key']) }
      end

      def donors
        @donors ||= keys('donors').map { |k| user(k) }
      end

      def charities
        @charities ||= @spec.fetch('charities').select { |u| (u['status'] || 'approved') == 'approved' }.map { |u| user(u['key']) }
      end

      def organisation_of(user)
        OrganisationsUser.where(user: user).order(:id).first&.organisation
      end

      # A synthetic client for a GoodCity order.
      def beneficiary(created_by:)
        names = @spec.fetch('names')
        @beneficiary_n += 1
        female = ctx.chance(0.55)
        Beneficiary.create!(
          title: female ? ctx.pick(%w[Ms Mrs Miss]) : 'Mr',
          first_name: ctx.pick(female ? names['given_female'] : names['given_male']),
          last_name: ctx.pick(names['surnames']),
          identity_type: ctx.reference.identity_type(ctx.chance(0.9) ? 'HKID' : 'ASRF'),
          identity_number: format('%04d', ctx.rng.rand(10_000)),
          phone_number: format('+8529%07d', 1_000_000 + ctx.rng.rand(8_999_999)),
          created_by: created_by
        )
      end
    end
  end
end

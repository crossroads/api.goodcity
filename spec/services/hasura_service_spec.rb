require 'rails_helper'

describe HasuraService do
  let(:now) { Time.now }
  let(:user) { create :user, :with_stock_fulfilment_role, :with_supervisor_role }

  let(:active_org_user) { create :organisations_user, :approved, user: user }
  let(:denied_org_user) { create :organisations_user, :denied, user: user }
  let(:pending_org_user) { create :organisations_user, :pending, user: user }
  let(:expired_org_user) { create :organisations_user, :expired, user: user }

  before { Timecop.freeze(now) }
  after  { Timecop.return }

  before do 
    touch(active_org_user, denied_org_user, pending_org_user, expired_org_user)
  end

  describe "JWT generation" do
    let(:token) { HasuraService.authenticate(user) }
    let(:token_reader) { Token.new(bearer: token, jwt_config: HasuraService.jwt_config) }
    let(:token_data) { token_reader.data[0] }
    let(:hasura_claims) { token_data["https://hasura.io/jwt/claims"] }

    before { expect(token_reader.valid?).to be(true) }

    it "returns a token" do 
      expect(token).not_to be_nil
    end

    it "expires after 1 hour" do
      Timecop.freeze(now + 59.minute)
      expect(token_reader.valid?).to eq(true)

      Timecop.freeze(now + 1.hour)
      expect(token_reader.valid?).to eq(false)
      expect(token_reader.errors.full_messages).to include('Expired token')
    end

    it "includes the hasura claims namespace" do 
      expect(hasura_claims).to be_a(Hash)
    end

    it "includes the user roles in the hasura claims" do 
      expect(hasura_claims["x-hasura-allowed-roles"]).to eq(['supervisor', 'stock_fulfilment', 'user', 'public'])
    end

    it "includes the user's active organisation ids in the hasura claims" do 
      expect(hasura_claims["x-hasura-organisation-ids"]).to eq(
        "{#{[active_org_user, pending_org_user].map(&:organisation_id).map(&:to_s).join(',')}}"
      )
    end

    it "includes the user id in the hasura claims" do 
      expect(hasura_claims["x-hasura-user-id"]).to eq(user.id.to_s)
    end

    it "sets the strongest role as the default role" do 
      expect(hasura_claims["x-hasura-default-role"]).to eq('supervisor')
    end

    it "includes the issuer set in the environment" do
      expect(token_data["issuer"]).not_to be_nil
      expect(token_data["issuer"]).to eq(ENV['HASURA_JWT_ISSUER'])
    end

    it "includes the audience set in the environment" do
      expect(token_data["audience"]).not_to be_nil
      expect(token_data["audience"]).to eq(ENV['HASURA_JWT_AUDIENCE'])
    end
  end
end

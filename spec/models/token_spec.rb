require "rails_helper"

describe "Token", :type => :model do
  let(:token)  { Token.new(bearer: bearer) }
  let(:bearer) { "Bearer test token" }
  let(:jwt_config) { Rails.application.secrets.jwt }

  context "initialization" do
    it "with valid bearer" do
      expect(token.instance_variable_get("@bearer")).to eql(bearer)
    end
  end

  context "generate" do
    it "with no extra parameters" do
      expect(JWT).to receive(:encode) do |args, secret_key, hmac_sha_algo|
        expect(args["iss"]).to eql(jwt_config[:issuer])
        expect(secret_key).to eql(jwt_config[:secret_key])
        expect(hmac_sha_algo).to eql(jwt_config[:hmac_sha_algo])
      end
      token.generate({})
    end
    it "with extra parameters to encode" do
      expect(JWT).to receive(:encode) do |args, secret_key, hmac_sha_algo|
        expect(args["user_id"]).to eql("123")
      end
      token.generate(user_id: "123")
    end
  end

  context "jwt_string" do
    it "should truncate 'Bearer '" do
      expect(token.send(:jwt_string)).to eql(bearer.sub('Bearer ', ''))
    end
  end

  context "token" do
    it "should call JWT.decode" do
      expect(JWT).to receive(:decode).with(
        token.send(:jwt_string),
        token.send(:secret_key),
        true, algorithm: 'HS256')
      token.send(:token)
    end
  end

  context "token_validation" do
    let(:now) { Time.current }
    let(:iat) { now.to_i }
    let(:exp) { (now + 14.days).to_i }
    let(:token_hash) { [{"iat" => iat, "exp" => exp}] }

    context "with valid token" do
      before { allow(token).to receive(:token).and_return(token_hash) }
      it {
        expect(token).to be_valid
      }
    end

    context "with empty jwt_string" do
      before { allow(token).to receive(:jwt_string).and_return('') }
      it { expect(token).to_not be_valid }
    end

    context "with expired token" do
      let(:exp) { 1.day.ago.to_i }
      it do
        payload = {
                    iss: jwt_config[:issuer],
                    exp: exp
                  }
        jwt_string = JWT.encode(payload, jwt_config[:secret_key], jwt_config[:hmac_sha_algo])
        expect{
          JWT.decode(jwt_string,
                     jwt_config[:secret_key],
                     true,
                     { algorithm: jwt_config[:hmac_sha_algo] }) }.to raise_error(JWT::DecodeError)
      end
    end

    context "with expiry before iat" do
      let(:iat) { (exp + 1.day).to_i }
      it do
        expect(token).to_not be_valid
        expect(token.errors.full_messages.join).to eql(I18n.t("token.invalid"))
      end
    end
  end

  context "jwt_config" do
    let(:conf) { {config: true} }
    before{ allow(Rails.application.secrets).to receive(:jwt).and_return(conf) }
    it{ expect(token.send(:jwt_config)).to eql(conf) }
  end

  context "configuration" do
    before do
      allow(token).to receive(:jwt_config).
      and_return( { secret_key: "123456", hmac_sha_algo: "SECURE", issuer: "ME" } )
    end
    it { expect(token.send(:secret_key)).to eql("123456") }
    it { expect(token.send(:hmac_sha_algo)).to eql("SECURE") }
    it { expect(token.send(:issuer)).to eql("ME") }
  end
end

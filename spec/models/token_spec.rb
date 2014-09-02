require 'rails_helper'

describe Token, :type => :model do

  let(:token)  { Token.new(bearer: bearer) }
  let(:bearer) { "Bearer test token" }

  context "initialization" do
    it "with valid bearer" do
      expect(token.instance_variable_get('@bearer')).to eql(bearer)
    end
  end

  context "generate" do
    it "with no extra parameters" do
      expect(JWT).to receive(:encode) do |args, secret_key, hmac_sha_algo|
        expect( args['otp_secret_key'] ).to eql( token.header )
        expect( args['iss'] ).to eql( Rails.application.secrets.jwt['issuer'] )
        expect( secret_key ).to eql( Rails.application.secrets.jwt['secret_key'] )
        expect( hmac_sha_algo  ).to eql( Rails.application.secrets.jwt['hmac_sha_algo'] )
      end
      token.generate
    end
    it "with extra parameters to encode" do
      expect(JWT).to receive(:encode) do |args, secret_key, hmac_sha_algo|
        expect( args['mobile'] ).to eql( '12345678' )
      end
      token.generate( mobile: '12345678' )
    end
  end

  context "header" do
    it "should truncate 'Bearer '" do
      expect(token.header).to eql( bearer.sub('Bearer ', '') )
    end
  end

  context "token" do

    it "should call JWT.decode" do
      expect(JWT).to receive(:decode).with(token.header, token.send(:secret_key), token.send(:hmac_sha_algo))
      token.send(:token)
    end
  end

  context "token_validation" do

    let(:now) { Time.now }
    let(:iat) { now.to_i }
    let(:exp) { (now + 14.days).to_i }
    let(:token_hash) { {'iat' => iat, 'exp' => exp} }
    before{ allow(token).to receive(:token).and_return(token_hash) }

    context "with valid token" do
      it { expect(token).to be_valid }
    end

    context "with empty header" do
      before{ allow(token).to receive(:header).and_return('') }
      it{ expect(token).to_not be_valid }
    end

    context "with expired token" do
      let(:exp) { (now - 1.day).to_i }
      it do
        expect(token).to_not be_valid
        expect(token.errors.full_messages.join).to eql(I18n.t('token.expired'))
      end
    end

    context "with iat in future" do
      let(:iat) { (now + 1.day).to_i }
      it do
        expect(token).to_not be_valid
        expect(token.errors.full_messages.join).to eql(I18n.t('token.invalid'))
      end
    end

    context "with expiry before iat" do
      let(:iat) { (exp + 1.day).to_i }
      it do
        expect(token).to_not be_valid
        expect(token.errors.full_messages.join).to eql(I18n.t('token.invalid'))
      end
    end

  end

  context "jwt_config" do
    let(:conf) { {config: true} }
    before{ allow(Rails.application.secrets).to receive(:jwt).and_return(conf) }
    it{ expect(token.send(:jwt_config)).to eql(conf) }
  end

  context "configuration" do
    before{ allow(token).to receive(:jwt_config).and_return({ 'secret_key' => '123456', 'hmac_sha_algo' => 'SECURE', 'issuer' => 'ME' }) }
    it{ expect( token.send(:secret_key) ).to eql( '123456' ) }
    it{ expect( token.send(:hmac_sha_algo) ).to eql( 'SECURE' ) }
    it{ expect( token.send(:issuer) ).to eql( 'ME' ) }
  end

end

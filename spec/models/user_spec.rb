require 'rails_helper'

describe User, :type => :model do

  let!(:user_valid_attr) {{
      mobile: "+85211111111",
      first_name: "John1",
      last_name: "Dey1",
      address_attributes: {district_id: "9", address_type: "profile"}
  }}

  let!(:user_invalid_attr) {{
      mobile: "85211111112",
      first_name: "John2",
      last_name: "Dey2"
  }}
  let(:user) { create :user }

  describe 'Associations' do
    it { should have_many :auth_tokens }
    it { should have_many :offers }
    it { should have_many :messages }
    it { should have_many :sent_messages }
    it { should belong_to :permission }
    it { should have_one  :address }
  end

  describe 'Database columns' do
    it{ should  have_db_column(:first_name).of_type(:string)}
    it{ should  have_db_column(:last_name).of_type(:string)}
    it{ should  have_db_column(:mobile).of_type(:string)}
  end

  describe "Validations" do
    it { should validate_presence_of(:mobile) }
    it { should validate_uniqueness_of(:mobile) }
  end

  describe 'Scope Methods' do
    describe '.find_all_by_otp_secret_key' do
      let!(:user) { create :user }
      it 'find user by otp_secret_key' do
        secret_key = user.auth_tokens.first.otp_secret_key
        expect(User.find_all_by_otp_secret_key(secret_key).first).to eq(user)
      end
    end

    describe '.check_for_mobile_uniqueness' do
      let!(:user) {create :user_with_token}
      it 'check for mobile number' do
        expect(User.check_for_mobile_uniqueness(user_valid_attr[:mobile]).first).to eq(user)
      end
    end

    describe '.creation_with_auth' do
      let!(:custom_user) {
        VCR.use_cassette "valid user with verified mobile" do
          User.creation_with_auth(user_valid_attr)
        end
      }
      let!(:twilio_error){
        VCR.use_cassette "invalid user with unverified mobile" do
          User.creation_with_auth(user_invalid_attr)
        end
      }

      it 'create a user' do
        expect(User.where("mobile=?", user_valid_attr[:mobile]).first).to eq(custom_user)
      end
      it 'raise error if mobile alreay exists' do
        user_with_same_mobile = User.new(user_valid_attr)
        expect {user_with_same_mobile.save!}.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'create an auth_token' do
        expect(custom_user.auth_tokens.count).to be >= 1
      end

      it 'create an address with provided district id' do
        expect(custom_user.address).not_to be_nil
        expect(custom_user.address.district_id).to eq(9)
      end

      it 'sms a verification pin' do
        expect(custom_user.most_recent_token.otp_code).not_to be_nil
      end

      it 'raise error if mobile is invalid' do
        expect(twilio_error).to eq("The 'To' number #{user_invalid_attr[:mobile]} is not a valid phone number")
      end
    end
  end

  describe '#get_friendly_token' do
    it 'give auth_token otp_secret_token' do
      user1_token = user.most_recent_token.otp_secret_key
      expect(user1_token).to eq(user.friendly_token)
    end
  end

  describe '#send_verification_pin' do

    let(:flowdock)   { EmailFlowdockService.new(user) }
    let(:twilio)     { TwilioService.new(user) }

    it "should send pin via Twilio" do
      expect(EmailFlowdockService).to receive(:new).with(user).and_return(flowdock)
      expect(flowdock).to receive(:send_otp)
      expect(TwilioService).to receive(:new).with(user).and_return(twilio)
      expect(twilio).to receive(:sms_verification_pin)
      user.send_verification_pin
    end

  end

  describe '#generate_auth_token' do
    it 'create an auth_token record, after user creation' do
      user = build(:user)
      expect(user.auth_tokens.size).to eq(0)
      user.save!
      expect(user.auth_tokens.size).to_not eq(0)
    end
  end

end

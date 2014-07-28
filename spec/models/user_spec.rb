require 'rails_helper'

describe User, :type => :model do

  let!(:user_valid_attr) {{
      mobile: "+919930001948",
      first_name: "John1",
      last_name: "Dey1"
  }}

  let!(:user_invalid_attr) {{
      mobile: "919930001999",
      first_name: "John2",
      last_name: "Dey2"
  }}
  let!(:user_fg) {create :user}

  describe 'Association' do
    it { should have_many :auth_tokens }
    it { should have_many :offers }
    it { should have_many :messages }
    it { should have_and_belong_to_many :permissions }
  end

  describe 'Database columns' do
    it{ should  have_db_column(:first_name).of_type(:string)}
    it{ should  have_db_column(:last_name).of_type(:string)}
    it{ should  have_db_column(:mobile).of_type(:string)}
    # it{ should  have_db_column(:district_id).of_type(:integer)}
  end

  describe 'Scope Methods' do
    describe '.find_user_based_on_auth' do
      it 'find user by otp_secret_key' do
        user1 = user_fg
        user2 = user_fg
        auth_user1_otp_skey = user1.auth_tokens.first.otp_secret_key
        expect(User.find_user_based_on_auth(auth_user1_otp_skey)).to eq (user1)
      end
    end

    describe '.check_for_mobile_uniqueness' do
      it 'check for mobile number' do
        user = create :user_with_specifics
        expect(User.check_for_mobile_uniqueness(user_valid_attr[:mobile])).to eq(user)
      end
    end

    describe '.creation_with_auth' do
      let!(:custom_user) {User.creation_with_auth(user_valid_attr)}

      it 'create a user' do
        expect(User.where("mobile=?", user_valid_attr[:mobile]).first).to eq(custom_user)
      end
      it 'raise error if mobile alreay exists' do
        user_with_same_mobile = User.new(user_valid_attr)
        expect {user_with_same_mobile.save}.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it 'create an auth_token' do
        expect(custom_user.auth_tokens.count).to be >= 1
      end

      it 'sms a verification pin' do
        expect(custom_user.auth_tokens.recent_auth_token.otp_code).not_to be_nil
      end

      it 'raise error if mobile is invalid' do
        twilio_error = User.creation_with_auth(user_invalid_attr)
        expect(twilio_error).to eq("The 'To' number #{user_invalid_attr[:mobile]} \
                                   is not a valid phone number")
      end
    end
  end

  describe '#get_friendly_token' do
    it 'give auth_token otp_secret_token' do
      user1_token = user_fg.auth_tokens.first.otp_secret_key
      expect(user1_token).to eq(user_fg.friendly_token)
    end
  end

  describe '#get_token_expiry_date' do
    it 'give auth_token otp_code_Expiry' do
      user1_token = user_fg.auth_tokens.first.otp_code_expiry
      expect(user1_token).to eq(user_fg.token_expiry)
    end
  end

  describe '#authenticate' do
    let!(:custom_user) {User.creation_with_auth(user_valid_attr)}

    it 'check for user mobile and successfully send sms' do
      ret_otp_secret = custom_user.authenticate(user_valid_attr[:mobile])
      expect(ret_otp_secret).not_to be_nil
      expect(ret_otp_secret).to eq(custom_user.friendly_token)
    end
  end

  describe '#send_verification_pin' do

    it 'update otp_code for the user' do
      before_n_after_otp_for_twilio_sms
      expect(@before_otp_code).not_to eq(@after_otp_code)
    end

    it 'update otp_code_Expiry for the user' do
      before_n_after_otp_for_twilio_sms
      expect(@before_otp_expiry).not_to eq(@after_otp_expiry)
    end

    it 'sms new otp_code' do
      # before_n_after_otp_for_twilio_sms
      # sms_text = "Your pin is #{@before_otp_code} and will expire by #{@before_otp_expiry}."
      # puts "#{sms_text}"
      # expect(current_text_message).not_to have_body sms_text
    end

    it 'return otp_secret_token' do
      before_n_after_otp_for_twilio_sms
      expect(@token_key).to eq(@valid_mobile_user.friendly_token)
    end

    after(:all) do
      User.destroy_all
    end
  end

  describe '#generate_auth_token' do
    it 'create a auth_token record, after user creation'
  end
end

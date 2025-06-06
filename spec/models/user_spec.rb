require "rails_helper"

describe User, :type => :model do
  let!(:mobile) { generate(:mobile) }
  let(:district) { create :district }
  let(:address_attributes) { {"district_id" => district.id.to_s, "address_type" => "profile"} }
  let(:user_attributes) { FactoryBot.attributes_for(:user).merge("mobile" => mobile, "address_attributes" => address_attributes).stringify_keys }
  let(:supervisor) { create(:user, :with_supervisor_role, :with_can_login_to_stock_permission, :with_can_login_to_admin_permission) }
  let(:order_fulfilment_user) { create(:user, :with_order_fulfilment_role, :with_can_login_to_stock_permission) }
  let(:reviewer) { create(:user, :with_reviewer_role, :with_can_login_to_admin_permission) }
  let(:charity) { create(:user, :charity) }

  let(:charity_users) { (1..5).map { create(:user, :charity) } }

  let(:invalid_user_attributes) { {"mobile" => "85211111112", "first_name" => "John2", "last_name" => "Dey2"} }

  let(:user) { create :user }

  describe "Associations" do
    it { is_expected.to have_many :auth_tokens }
    it { is_expected.to have_many :offers }
    it { is_expected.to have_many :messages }
    it { is_expected.to have_many :user_roles }
    it { is_expected.to have_many :requested_packages }
    it { is_expected.to have_many(:roles).through(:user_roles) }
    it { is_expected.to have_one :address }
  end

  describe "Database columns" do
    it { is_expected.to have_db_column(:first_name).of_type(:string) }
    it { is_expected.to have_db_column(:last_name).of_type(:string) }
    it { is_expected.to have_db_column(:mobile).of_type(:string) }
    it { is_expected.to have_db_column(:other_phone).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:last_connected).of_type(:datetime) }
    it { is_expected.to have_db_column(:last_disconnected).of_type(:datetime) }
    it { is_expected.to have_db_column(:title).of_type(:string) }
    it { is_expected.to have_db_column(:is_mobile_verified).of_type(:boolean) }
    it { is_expected.to have_db_column(:is_email_verified).of_type(:boolean) }
    it { is_expected.to have_db_column(:receive_email).of_type(:boolean) }
  end

  describe "Validations" do
    context "mobile" do
      it { is_expected.to validate_presence_of(:mobile) }
      context "uniqueness" do
        let(:user) { User.new(mobile: mobile) }
        before { create(:user, mobile: mobile) }
        it do
          expect(user.tap(&:valid?).errors[:mobile]).to include("has already been taken")
        end
      end

      it "allows a blank mobile if an email is present" do
        user = User.new(mobile: "", email: "some@email.com")
        expect(user.valid?).to be_truthy
      end

      it "allows a blank email if a mobile is present" do
        user = User.new(mobile: "+85291111111", email: "")
        expect(user.valid?).to be_truthy
      end

      it "allows a blank email and blank email for disabled user" do
        user = User.new(mobile: "", email: "", disabled: true)
        expect(user.valid?).to be_truthy
      end

      it "do not allows invalid hk number" do
        user = User.new(mobile: "+44123456675")
        expect(user.valid?).to be_falsey
      end

      it "prevents a blank mobile and blank email" do
        user = User.new(mobile: "", email: "")
        expect(user.valid?).to be_falsey
      end

      it { is_expected.to allow_value("+85251234567").for(:mobile) }
      it { is_expected.to allow_value("+85261234567").for(:mobile) }
      it { is_expected.to allow_value("+85291234567").for(:mobile) }
      it { is_expected.to_not allow_value("+85211234567").for(:mobile) }
      it { is_expected.to_not allow_value("+44123456675").for(:mobile) }
      it { is_expected.to_not allow_value("4412345").for(:mobile) }
      it { is_expected.to_not allow_value("invalid").for(:mobile) }
    end

    context "email" do
      it { is_expected.to allow_value("abc@gmail.com").for(:email) }
      it { is_expected.to allow_value("abc#pqr@gmail.com").for(:email) }
      it { is_expected.to allow_value("abc-pqr@gmail.com").for(:email) }
      it { is_expected.to allow_value("abc.pqr.xyz@gmail.com").for(:email) }
      it { is_expected.to_not allow_value("abc @gmail.com").for(:email) }
      it { is_expected.to_not allow_value("abc@ gmail.com").for(:email) }
      it { is_expected.to_not allow_value("abc @ gmail.com").for(:email) }
      it { is_expected.to_not allow_value("abc@@gmail.com").for(:email) }
      it { is_expected.to_not allow_value("abc.gmail.com").for(:email) }
    end

    context "title" do
      it { is_expected.to allow_value("Mr").for(:title) }
      it { is_expected.to allow_value("Mrs").for(:title) }
      it { is_expected.to allow_value("Miss").for(:title) }
      it { is_expected.to allow_value("Ms").for(:title) }
      it { is_expected.to_not allow_value("Mister").for(:title) }
      it { is_expected.to_not allow_value("").for(:title) }
    end

    context "preferred_language" do
      it { is_expected.to allow_value(nil).for(:preferred_language) }
      it { is_expected.to allow_value("en").for(:preferred_language) }
      it { is_expected.to allow_value("zh-tw").for(:preferred_language) }
      it { is_expected.to_not allow_value("fr").for(:preferred_language) }
      it { is_expected.to_not allow_value("").for(:preferred_language) }
    end
  end

  describe ".search" do
    let(:user) { create :user, first_name: "Abul", last_name: "Asar", email: "goodcity@team.com", mobile: "+85287655678" }

    before { touch(user) }

    it { expect(User.search("")).not_to include(user) }
    it { expect(User.search("@@@@")).not_to include(user) }
    it { expect(User.search("Abul")).to include(user) }
    it { expect(User.search("Asar")).to include(user) }
    it { expect(User.search("Abul Asar")).to include(user) }
    it { expect(User.search("abul asar")).to include(user) }
    it { expect(User.search("ul as")).to include(user) }
    it { expect(User.search("goodcity")).to include(user) }
    it { expect(User.search("123@890.com")).not_to include(user) }
    it { expect(User.search("good@890.hk")).not_to include(user) }
    it { expect(User.search("goodcity@gmail.com")).not_to include(user) }
    it { expect(User.search("goodcity@team")).to include(user) }
    it { expect(User.search("87655678")).to include(user) }

    context 'without a first or last name' do
      let(:user) { create :user, first_name: "", last_name: "", email: "goodcity@team.com", mobile: "+85287655678" }

      before { touch(user) }

      it { expect(User.search("goodcity")).to include(user) }
      it { expect(User.search("87655678")).to include(user) }
    end
  end

  # describe ".recent_orders_created_for" do
  #   it "will return recent 5 users who created orders" do
  #   end

  #   it "will return recent 5 orders according to role type" do
  #   end

  #   it "will return recent users for orders authorised by Logged in User" do
  #   end

  #   it "will return nothing if logged user has not created any order" do
  #   end
  # end

  describe ".creation_with_auth" do
    context "when mobile does not exist" do
      let(:new_user) { build(:user) }
      it "should create new user" do
        allow(new_user).to receive(:send_verification_pin)
        expect(User).to receive(:new).with(user_attributes).and_return(new_user)
        User.creation_with_auth(user_attributes, DONOR_APP)
      end
    end

    context "when mobile does exist" do
      it "should send pin to existing user" do
        user = create(:user, mobile: mobile)
        user_attributes["email"] = nil
        expect(User).to receive(:find_user_by_mobile_or_email).with(mobile, nil).and_return(user)
        expect(user).to receive(:send_verification_pin)
        User.creation_with_auth(user_attributes, DONOR_APP)
      end
    end

    context "when email does exist" do
      it "should send pin to existing user" do
        user = create(:user, email: "abc@example.com")
        user_attributes["mobile"] = nil
        user_attributes["email"] = "abc@example.com"
        expect(User).to receive(:find_user_by_mobile_or_email).with(nil, "abc@example.com").and_return(user)
        User.creation_with_auth(user_attributes, BROWSE_APP)
      end
    end

    context "when email does not exist" do
      let(:new_user) { build(:user, mobile: nil) }
      it "should create new user" do
        allow(new_user).to receive(:send_verification_pin)
        expect(User).to receive(:new).with(user_attributes).and_return(new_user)
        User.creation_with_auth(user_attributes, BROWSE_APP)
      end
    end

    context "when mobile and email are blank" do
      let(:new_user) { build(:user, mobile: nil) }
      let(:payload) { user_attributes.except('mobile', 'email') }

      it "should raise validation error" do
        user = User.creation_with_auth(payload, DONOR_APP)
        expect(user.errors[:mobile]).to include("can't be blank")
      end
    end

    %w[en zh-tw].each do |locale|
      context "when locale is #{locale}" do
        it "saves preferred_language field as #{locale}" do
          I18n.with_locale(locale) do
            user = User.creation_with_auth(user_attributes, DONOR_APP)
            expect(user.preferred_language).to eq(locale)
          end
        end
      end
    end

    context "when user is present" do
      it "should recycle otp_auth_key" do
        user = create(:user, mobile: mobile, email: "abc@example.com")
        expect(AuthenticationService).to receive(:otp_auth_key_for).with(user,refresh: true)
        User.creation_with_auth(user_attributes, BROWSE_APP)
      end
    end

    context "when user is not present" do
      it "should not recycle otp_auth_key" do
        new_user = build(:user)
        allow(new_user).to receive(:send_verification_pin)
        expect(User).to receive(:new).with(user_attributes).and_return(new_user)
        expect(AuthenticationService).not_to receive(:otp_auth_key_for)
        User.creation_with_auth(user_attributes, BROWSE_APP)
      end
    end
  end

  describe "#send_verification_pin" do
    let(:twilio) { TwilioService.new(user) }
    let(:mobile) { '+85290369036' }

    it "should send pin via Twilio" do
      expect(TwilioService).to receive(:new).with(user, user.mobile).and_return(twilio)
      expect(twilio).to receive(:sms_verification_pin)
      user.send_verification_pin(DONOR_APP, user.mobile, nil)
    end

    it 'sends verification number to the provided mobile number only' do
      twilio = TwilioService.new(user, mobile)
      expect(TwilioService).to receive(:new).with(user, mobile).and_return(twilio)
      expect(twilio).to receive(:sms_verification_pin)
      user.send_verification_pin(DONOR_APP, mobile, nil)
      expect(twilio.mobile).to eq(mobile)
    end

    it "sends pin via email if email is provided" do
      expect(GoodcityMailer).to receive_message_chain(:with, :send_pin_email, :deliver_later)
      user.send_verification_pin(DONOR_APP, nil, "test@example.com")
    end

    it "sends pin via email if the user flag 'send_pin_via_email' is true" do
      expect(GoodcityMailer).to receive_message_chain(:with, :send_pin_email, :deliver_later)
      user.update_column(:send_pin_via_email, true)
      user.send_verification_pin(DONOR_APP, mobile, nil)
    end
  end

  describe "#set_verified_flag for email and mobile" do
    let(:user) { create(:user, mobile: "+85289898978", email: "test@hk.org") }

    it "should set verified flag for email" do
      expect(user.is_email_verified).to be_falsey
      user.set_verified_flag('email')
      expect(user.is_email_verified).to be_truthy
    end

    it "should set verified flag for mobile" do
      expect(user.is_mobile_verified).to be_falsey
      user.set_verified_flag('mobile')
      expect(user.is_mobile_verified).to be_truthy
    end

    it "should reset verified flag when mobile is updated" do
      user.update_column(:is_mobile_verified, true)

      expect{
        user.mobile = nil
        user.save
      }.to change{ user.is_mobile_verified}.to(false)
    end

    it "should reset verified flag when email is updated" do
      user.update_column(:is_email_verified, true)

      expect{
        user.email = nil
        user.save
      }.to change{ user.is_email_verified}.to(false)
    end
  end

  describe "#refresh_auth_token!" do
    it "triggers after user creation" do
      user = build(:user)

      expect(user).to receive(:refresh_auth_token!).once.and_call_original
      expect { user.save! }.to change(AuthToken, :count).by(1)
      expect(user.reload.auth_tokens.size).to eq(1)
    end

    it "deletes old tokens and recreates a new one" do
      user  = create(:user)
      expect {
        user.refresh_auth_token!
      }.to change { user.reload.auth_tokens.first.id }
    end
  end

  # TODO: NEED FIX, INTERMITENT FAILURE
  # describe "#system_user" do
  #   it "should return default user" do
  #     expect(User.system_user.first_name).to eq("GoodCity")
  #     expect(User.system_user.last_name).to eq("Team")
  #   end
  # end

  describe "#system_user?" do
    it "should be false" do
      expect(build(:user).system_user?).to eql(false)
    end
    it "should be true" do
      expect(User.system_user.system_user?).to eql(true)
    end
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "#online?" do
    it "should be false" do
      expect(build(:user).online?).to eq(false)
    end

    it "should be false" do
      expect(build(:user, last_connected: 1.hour.ago).online?).to eq(true)
    end
  end

  describe '#locale' do
    let(:user) { create(:user, preferred_language: 'zh-tw') }
    it 'returns the users preferred language' do
      expect(user.locale).to eq('zh-tw')
    end

    context 'if preferred_language is nil' do
      let(:user) { create(:user, preferred_language: nil) }
      it 'returns en as the locale' do
        expect(user.locale).to eq('en')
      end
    end
  end

  describe "#user_role_names" do
    it "returns role names for user" do
      user = create :user, :reviewer
      expect(user.user_role_names).to include("Reviewer")
      expect(user.user_role_names.count).to eq(1)
    end

    it 'returns valid role names for user' do
      user = create :user
      reviewer_role = create :role, name: "Reviewer"
      supervisor_role = create :role, name: "Supervisor"
      create :user_role, user: user, role: reviewer_role
      create :user_role, user: user, role: supervisor_role, expires_at: 5.days.ago

      expect(user.user_role_names).to include("Reviewer")
      expect(user.user_role_names.count).to eq(1)

      expect(user.user_role_names).to_not include("Supervisor")
    end
  end

  describe "#user_permissions_names" do
    it "returns all names of permissions assigned to user" do
      permissions = order_fulfilment_user.user_permissions_names
      expect(permissions.count).to eq(1)
      expect(permissions).to eq(["can_login_to_stock"])
    end
  end

  describe '.downcase_email' do
    it 'saves user with always downcasing email' do
      email = 'TeST@Gmail.COM'
      user = build(:user)
      user.email = email
      user.save
      expect(user.reload.email).to eq(email.downcase)
    end
  end

  describe "#allowed_login?" do
    context "with stock login permission" do
      it "returns true if user has stock login permission and app is stock app" do
        expect(order_fulfilment_user.allowed_login?(STOCK_APP)).to be_truthy
      end

      it "returns true if user do not have stock login permission and app is stock app" do
        expect(user.allowed_login?(STOCK_APP)).to be_truthy
      end

      it "returns false if user has stock login permission and app is admin app" do
        expect(order_fulfilment_user.allowed_login?(ADMIN_APP)).to be_falsey
      end

      it "returns true if user has stock login permission and app is donor app" do
        expect(order_fulfilment_user.allowed_login?(DONOR_APP)).to be_truthy
      end

      it "returns true if user has stock login permission and app is browse app" do
        expect(order_fulfilment_user.allowed_login?(BROWSE_APP)).to be_truthy
      end
    end

    context "with admin login permission" do
      it "returns true if user have admin login permission and app is admin app" do
        expect(supervisor.allowed_login?(ADMIN_APP)).to be_truthy
      end

      it "returns false if user do not admin login permission and app is admin app" do
        expect(charity.allowed_login?(ADMIN_APP)).to be_falsey
      end

      it "returns false if user do not have admin login permission and app is admin app" do
        expect(order_fulfilment_user.allowed_login?(ADMIN_APP)).to be_falsey
      end

      it "returns true if user have admin login permission app is donor app" do
        expect(supervisor.allowed_login?(DONOR_APP)).to be_truthy
      end

      it "returns true if user has admin login permission and app is stock app" do
        expect(reviewer.allowed_login?(STOCK_APP)).to be_truthy
      end

      it "returns true if user has admin app login permission and app browse app" do
        expect(supervisor.allowed_login?(BROWSE_APP)).to be_truthy
      end
    end

    context "with browse login permission" do
      it "returns true if user have browse login permission and app is browse app" do
        expect(charity.allowed_login?(BROWSE_APP)).to be_truthy
      end

      it "returns true if user do not browse login permission and app is browse app" do
        expect(supervisor.allowed_login?(BROWSE_APP)).to be_truthy
      end

      it "returns true if user have browse login permission and app is not browse app" do
        expect(charity.allowed_login?(STOCK_APP)).to be_truthy
      end

      it "returns true if user have browse login permission app is donor app" do
        expect(charity.allowed_login?(DONOR_APP)).to be_truthy
      end

      it "returns true if user has browse login permission and app is stock app" do
        expect(charity.allowed_login?(STOCK_APP)).to be_truthy
      end
    end

    context "to donor app" do
      it "returns true for user without any permissions" do
        expect(user.allowed_login?(DONOR_APP)).to be_truthy
      end

      it "returns true if user have permission only to login to stock app" do
        expect(order_fulfilment_user.allowed_login?(DONOR_APP)).to be_truthy
      end

      it "returns true if user have permission only to login to admin app" do
        expect(supervisor.allowed_login?(DONOR_APP)).to be_truthy
      end

      it "returns true if user have permission only to login to browse app" do
        expect(charity.allowed_login?(DONOR_APP)).to be_truthy
      end
    end
  end

  context "find_user_by_mobile_or_email" do
    let(:user) { create(:user) }

    it "returns the user by mobile" do
      expect(User.find_user_by_mobile_or_email(user.mobile, nil)).to eql(user)
    end
    it "returns the user by email" do
      expect(User.find_user_by_mobile_or_email(nil, user.email)).to eql(user)
    end
    it "does not return a user when email is blank" do
      user.update_column(:email, '')
      expect(User.find_user_by_mobile_or_email(nil, '')).to eql(nil)
    end
  end

  describe "Lifecycle hooks" do
    let(:user) { create :user, :with_token }

    before { touch(user) }

    context "when destroyed" do
      it "deletes any auth tokens remaining" do
        expect {
          user.destroy
        }.to change {
          AuthToken.where(user: user).count
        }.from(1).to(0)
      end
    end
  end

  describe '.with_organisation_status' do
    let(:role_1) { create(:role, name: "Role 1", level: 1) }
    let(:role_2) { create(:role, name: "Role 2", level: 5) }

    let(:user_1) { create(:user, :charity) }
    let(:user_2) { create(:user, :charity) }
    let(:user_3) { create(:user, :charity) }
    let(:user_4) { create(:user, :charity) }
    let(:user_5) { create(:user, :charity) }
    let(:user_6) { create(:user) }

    before do
      User.destroy_all # Ensure no lingering users exist

      role_1.grant(user_1)
      role_2.grant(user_2)
      role_1.grant(user_3)
      role_1.grant(user_4)
      role_2.grant(user_5)
      role_2.grant(user_6)

      user_5.organisations_users.first.update(status: 'expired')
      user_4.organisations_users.first.update(status: 'denied')
    end

    it 'search users by organisation status' do
      users = User.with_organisation_status(%w[pending approved])
      expect(users.count).to eq(3)
      expect(users).to match_array([user_1, user_2, user_3])

      users = User.with_organisation_status(%w[expired denied])
      expect(users.count).to eq(2)
      expect(users).to match_array([user_4, user_5])
    end
  end

  describe "Scopes" do
    describe "with_permissions" do
      let(:user_with_role) { create(:user) }
      let(:user_without_role) { create(:user) }
      let(:user_with_expired_role) { create(:user) }
      let(:users) { [user_with_role, user_without_role, user_with_expired_role] }

      let(:role) { create(:role,  :with_permissions, permissions: ['can_manage_offers', 'can_manage_messages']) }
      let(:unrelated_role) { create(:role, :with_permissions, permissions: ['can_manage_orders']) }

      before do
        create(:user_role, user: user_with_role, role: role)
        create(:user_role, user: user_with_expired_role, role: role, expires_at: 1.year.ago)

        users.each { |u| unrelated_role.grant(u) }
      end

      it "only returns users with active (non-expired) permission" do
        res = User.with_permissions(:can_manage_offers)
        expect(res.pluck(:id)).to include(user_with_role.id)
      end
    end
  end
end

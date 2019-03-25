require "rails_helper"

describe User, :type => :model do
  let!(:mobile) { generate(:mobile) }
  let(:address_attributes) { {"district_id" => "9", "address_type" => "profile"} }
  let(:user_attributes) { FactoryBot.attributes_for(:user).merge("mobile" => mobile, "address_attributes" => address_attributes).stringify_keys }
  let(:supervisor) {
    create(:user, :with_multiple_roles_and_permissions,
           roles_and_permissions: {"Supervisor" => ["can_login_to_stock", "can_login_to_admin"]})
  }
  let(:order_fulfilment_user) {
    create(:user, :with_multiple_roles_and_permissions,
           roles_and_permissions: {"Order fulfilment" => ["can_login_to_stock"]})
  }
  let(:reviewer) {
    create(:user, :with_multiple_roles_and_permissions,
           roles_and_permissions: {"Reviewer" => ["can_login_to_admin"]})
  }
  let(:charity) {
    create(:user, :with_multiple_roles_and_permissions,
           roles_and_permissions: {"Charity" => ["can_login_to_browse"]})
  }

  let(:charity_users) {
    (1..5).map {
      create(:user, :with_multiple_roles_and_permissions,
             roles_and_permissions: {"Charity" => ["can_login_to_browse"]})
    }
  }

  let(:invalid_user_attributes) { {"mobile" => "85211111112", "first_name" => "John2", "last_name" => "Dey2"} }

  let(:user) { create :user }

  describe "Associations" do
    it { is_expected.to have_many :auth_tokens }
    it { is_expected.to have_many :offers }
    it { is_expected.to have_many :messages }
    it { is_expected.to have_many :user_roles }
    it { is_expected.to have_many(:roles).through(:user_roles) }
    it { is_expected.to have_one :address }
  end

  describe "Database columns" do
    it { is_expected.to have_db_column(:first_name).of_type(:string) }
    it { is_expected.to have_db_column(:last_name).of_type(:string) }
    it { is_expected.to have_db_column(:mobile).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:last_connected).of_type(:datetime) }
    it { is_expected.to have_db_column(:last_disconnected).of_type(:datetime) }
    it { is_expected.to have_db_column(:title).of_type(:string) }
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

      context "for stock" do
        it "allows blank" do
          user = User.new(mobile: "")
          user.request_from_stock = true
          expect(user.valid?).to be_truthy
        end

        it "allows valid mobile number" do
          user = User.new(mobile: "+85251234567")
          user.request_from_stock = true
          expect(user.valid?).to be_truthy
        end

        it "do not allows invalid hk number" do
          user = User.new(mobile: "+44123456675")
          user.request_from_stock = true
          expect(user.valid?).to be_falsey
        end
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
  end

  describe ".search" do
    it "will return users according to searchText" do
      search_options = {search_text: charity_users.first.first_name, role_name: "Charity"}
      expect(User.search(search_options).pluck(:id)).to include(charity_users.first.id)
    end

    it "will return users according to role type" do
      search_options = {search_text: charity_users.first.first_name, role_name: "Charity"}
      expect(User.search(search_options).first.roles.pluck(:name)).to include("Charity")
    end

    it "will return users based on email from search text" do
      charity_users.first.update(email: "charity@abc.com")
      search_options = {search_text: charity_users.first.email, role_name: "Charity"}
      expect(User.search(search_options).pluck(:id)).to include(charity_users.first.id)
    end

    it "will return users based on mobile from search text" do
      search_options = {search_text: charity_users.first.mobile, role_name: "Charity"}
      expect(User.search(search_options).pluck(:id)).to include(charity_users.first.id)
    end

    it "will return nothing if searchText does not match any users" do
      search_options = {search_text: "zzzzz", role_name: "Charity"}
      expect(User.search(search_options).length).to eq(0)
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
        expect(User).to receive(:find_user_by_mobile_or_email).with(mobile, nil).and_return(user)
        expect(user).to receive(:send_verification_pin)
        User.creation_with_auth(user_attributes, DONOR_APP)
      end
    end

    context "when mobile blank" do
      let(:mobile) { nil }
      it "should raise validation error" do
        user = User.creation_with_auth(user_attributes, DONOR_APP)
        expect(user.errors[:mobile]).to include("can't be blank")
        expect(user.errors[:mobile]).to include("is invalid")
      end
    end
  end

  describe "#send_verification_pin" do
    let(:slack) { SlackPinService.new(user) }
    let(:twilio) { TwilioService.new(user) }

    it "should send pin via Twilio" do
      expect(SlackPinService).to receive(:new).with(user).and_return(slack)
      expect(slack).to receive(:send_otp)
      expect(TwilioService).to receive(:new).with(user).and_return(twilio)
      expect(twilio).to receive(:sms_verification_pin)
      user.send_verification_pin(DONOR_APP, user.mobile, nil)
    end
  end

  describe "#generate_auth_token" do
    it "create an auth_token record, after user creation" do
      user = build(:user)
      expect(user.auth_tokens.size).to eq(0)
      user.save!
      expect(user.auth_tokens.size).to_not eq(0)
    end
  end

  describe "#system_user" do
    it "should return default user" do
      expect(User.system_user.first_name).to eq("GoodCity")
      expect(User.system_user.last_name).to eq("Team")
    end
  end

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

  describe "#user_role_names" do
    it "returns role names for user" do
      user = create :user, :reviewer
      expect(user.user_role_names).to include("Reviewer")
      expect(user.user_role_names.count).to eq(1)
    end
  end

  describe "#user_permissions_names" do
    it "returns all names of permissions assigned to user" do
      permissions = order_fulfilment_user.user_permissions_names
      expect(permissions.count).to eq(1)
      expect(permissions).to eq(["can_login_to_stock"])
    end
  end

  describe "#allowed_login?" do
    context "with stock login permission" do
      it "returns true if user has stock login permission and app is stock app" do
        expect(order_fulfilment_user.allowed_login?(STOCK_APP)).to be_truthy
      end

      it "returns false if user do not have stock login permission and app is stock app" do
        expect(user.allowed_login?(STOCK_APP)).to be_falsey
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

      it "returns false if user has admin login permission and app is stock app" do
        expect(reviewer.allowed_login?(STOCK_APP)).to be_falsey
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

      it "returns false if user have browse login permission and app is not browse app" do
        expect(charity.allowed_login?(STOCK_APP)).to be_falsey
      end

      it "returns true if user have browse login permission app is donor app" do
        expect(charity.allowed_login?(DONOR_APP)).to be_truthy
      end

      it "returns false if user has browse login permission and app is stock app" do
        expect(charity.allowed_login?(STOCK_APP)).to be_falsey
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
end

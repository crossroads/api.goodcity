require "rails_helper"

  # :organisations_user: {
  #   :organisation_id,
  #   :position,
  #   user_attributes: {
  #     :first_name,
  #     :last_name,
  #     :mobile,
  #     :email
  #   }

describe OrganisationsUserBuilder do
  let(:organisation) { create :organisation}
  let(:user_attributes) do
    FactoryBot.attributes_for(:user, :with_email, mobile:'+85252345678')
  end

  let(:user_attributes_without_mobile) do
    FactoryBot.attributes_for(:user, :with_email)
  end

  let(:user_attributes_with_invalid_mobile) do
    FactoryBot.attributes_for(:user, :with_email, mobile: "+44123456675")
  end

  let(:update_user_attributes) do
    FactoryBot.attributes_for(:user, :with_email, mobile:'+85252345678', last_name: "Cooper")
  end

  let(:organisations_user) { create :organisations_user }
  let(:organisations_user_params) do
    FactoryBot.attributes_for(:organisations_user, organisation_id: "#{organisation.id}", position: "#{position}" , user_attributes: user_attributes)
  end

  let(:organisation_user_params_without_mobile) do
    FactoryBot.attributes_for(:organisations_user, organisation_id: "#{organisation.id}", position: "#{position}" , user_attributes: user_attributes_without_mobile)
  end

  let(:organisation_user_params_with_invalid_mobile) do
    FactoryBot.attributes_for(:organisations_user, organisation_id: "#{organisation.id}", position: "#{position}", user_attributes: user_attributes_with_invalid_mobile)
  end

  let(:update_organisations_user_params) do
    FactoryBot.attributes_for(:organisations_user, id: "#{organisations_user.id}", position: "Updated position", user_attributes: update_user_attributes)
  end

  let(:user) { create :user }
  let(:user1) { create :user, mobile: user_attributes[:mobile] }
  let(:position) { 'Admin' }

  let(:organisations_user_builder) { OrganisationsUserBuilder.new(organisations_user_params.stringify_keys, BROWSE_APP) }
  let(:organisation_user_builder_with_invalid_mobile_number) { OrganisationsUserBuilder.new(organisation_user_params_with_invalid_mobile.stringify_keys, BROWSE_APP) }
  let(:organisations_user_builder_without_mobile) { OrganisationsUserBuilder.new(organisation_user_params_without_mobile.stringify_keys, BROWSE_APP) }
  let(:update_organisations_user_builder) { OrganisationsUserBuilder.new(update_organisations_user_params.stringify_keys, BROWSE_APP) }
  let(:mobile) { '+85251111111' }
  let!(:role) { create :charity_role }
  let(:subject) { JSON.parse(response.body) }

  context "initialization" do
    it { expect(organisations_user_builder.instance_variable_get("@organisation_id")).to eql(organisation.id) }
    it { expect(organisations_user_builder.instance_variable_get("@user_attributes")).to eql(user_attributes) }
    it { expect(organisations_user_builder.instance_variable_get("@mobile")).to eql(user_attributes['mobile']) }
    it { expect(organisations_user_builder.instance_variable_get("@position")).to eql(position) }
    it { expect(update_organisations_user_builder.instance_variable_get("@organisations_user")).to eql(organisations_user) }
    it { expect(organisations_user_builder.instance_variable_get("@app_name")).to eql(BROWSE_APP) }
  end

  context "build" do

    before(:each) {
      User.current_user = user
    }

    context 'for stock app' do
      it "adds new user if mobile is blank and associates it with organisation" do
        expect{
          organisations_user_builder_without_mobile.build
        }.to change{User.count}.by(1).and change{OrganisationsUser.count}.by(1)
      end
    end

    it "do not creates organisations_users and user record if user is invalid. e.g mobile is invalid" do
      expect{
        organisation_user_builder_with_invalid_mobile_number.build
      }.to change{User.count}.by(0).and change{OrganisationsUser.count}.by(0)
    end

    it "adds new user if mobile does not exist and associates it with organisation" do
      expect{
        organisations_user_builder.build
      }.to change{User.count}.by(1).and change{OrganisationsUser.count}.by(1)
    end

    it "do not add user to organisation if mobile number already in organisation" do
      organisations_user1 = create :organisations_user, user: user1, organisation: organisation
      expect(organisations_user_builder.build).to eq({ 'result' => false, 'errors' => "Mobile has already been taken" })
      expect(OrganisationsUser.count).to eq(1)
    end

    it "associates charity_role to user if user added in organisation" do
      expect{
        organisations_user_builder.build
      }.to change{OrganisationsUser.count}.by(1)
      expect(OrganisationsUser.last.user.roles).to include(role)
    end

    it "twilio send_message after organisations_user creation" do
      allow(TwilioService.new(user)).to receive(:send_welcome_msg).and_return({:to=>"+85252345678", :body=>"#{user.full_name} has added you to the GoodCity for Charities platform. Please download the app and log in using this mobile number.\n"})
    end
  end

  context "update" do
    it "updates existing organisations user position" do
      update_organisations_user_builder.update
      expect(OrganisationsUser.first.position).to eq(update_organisations_user_params[:position])
    end

    it "updates user details belonging to organisation" do
      update_organisations_user_builder.update
      expect(OrganisationsUser.first.user.last_name).to eq(update_user_attributes[:last_name])
    end
  end
end

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
    FactoryBot.attributes_for(:user, :with_email)
  end
  let(:organisations_user_params) do
    FactoryBot.attributes_for(:organisations_user, organisation_id: "#{organisation.id}", position: "#{position}" , user_attributes: user_attributes)
  end

  let(:user) { create :user }
  let(:user1) { create :user, mobile: user_attributes[:mobile] }
  let(:position) { 'Admin' }

  let(:organisations_user_builder) { OrganisationsUserBuilder.new(organisations_user_params) }
  let(:mobile) { '+85251111111' }
  let!(:role) { create :charity_role }
  let(:subject) { JSON.parse(response.body) }

  context "initialization" do
    it { expect(organisations_user_builder.instance_variable_get("@organisation_id")).to eql(organisation.id) }
    it { expect(organisations_user_builder.instance_variable_get("@user_attributes")).to eql(user_attributes) }
    it { expect(organisations_user_builder.instance_variable_get("@mobile")).to eql(user_attributes[:mobile]) }
    it { expect(organisations_user_builder.instance_variable_get("@position")).to eql(position) }
  end

  context "build" do
    it "adds new user if mobile does not exist and associates it with organisation" do
      organisations_user_builder.build
      expect(User.count).to eq(2)
      expect(OrganisationsUser.count).to eq(1)
    end

    it "do not add user to organisation if mobile number already in organisation" do
      organisations_user1 = create :organisations_user, user: user1, organisation: organisation
      expect(organisations_user_builder.build).to eq({ 'result' => false, 'errors' => "User's already exist in organisation" })
      expect(OrganisationsUser.count).to eq(1)
    end

    it "associates charity_role to user if user added in organisation" do
      organisations_user_builder.build
      expect(OrganisationsUser.count).to eq(1)
      expect(OrganisationsUser.last.user.roles).to include(role)
    end

    it "sends twilio send_message after organisations_user creation" do
    end
  end
end

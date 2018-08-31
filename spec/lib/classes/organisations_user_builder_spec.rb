require "rails_helper"

describe OrganisationsUserBuilder do
  let(:organisation){ create :organisation}
  let(:user){ create :user}
  let(:organisations_user){ create :organisations_user, user: user, organisation: organisation }
  let(:organisations_user_builder)  {OrganisationsUserBuilder.new(organisations_user)}
  let!(:role) { create :charity_role}

  context "initialization" do
    it { expect(organisations_user_builder.instance_variable_get("@organisations_user")).to eql(organisations_user) }
    it { expect(organisations_user_builder.instance_variable_get("@organisation_id")).to eql(organisations_user.organisation.id) }
    it { expect(organisations_user_builder.instance_variable_get("@user")).to eql(organisations_user.user) }
  end

  context "build" do
    it "adds new user if mobile does not exist and associates it with organisation" do
    end

    it "updates user if already exist with mobile number" do
    end

    it "adds user to organisation if user does not exist in organisation" do
    end

    it "associates charity_role to user if user added in organisation" do
    end

    it "sends twilio send_message after organisations_user creation" do
    end
  end
end

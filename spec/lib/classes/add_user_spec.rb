require "rails_helper"

describe AddUser do

  let(:add_user)  {AddUser.new("Satya", "Nadella", "+85261111116", "Microsoft Corp")}

  context "initialization" do
    it { expect(add_user.instance_variable_get("@user").first_name).to eql("Satya") }
    it { expect(add_user.instance_variable_get("@user").last_name).to eql("Nadella") }
    it { expect(add_user.instance_variable_get("@user").mobile).to eql("+85261111116") }
    it { expect(add_user.instance_variable_get("@o_name")).to eql("Microsoft Corp") }
  end

  context "add_user_to_organisation" do
    it "should add user to organisation" do
      org =  FactoryGirl.create(:organisation, name_en: "Microsoft Corp")
      expect(add_user.add_user_to_organisation).to include(add_user.instance_variable_get("@user"))
      expect(org.users).to include(add_user.instance_variable_get("@user"))
    end

    it "should not add user to organisation" do
      expect(add_user.add_user_to_organisation).to eq(nil)
    end
  end
end

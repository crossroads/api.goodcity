require "rails_helper"

describe "UserSafeDeleteJob", type: :job do

  let(:user_safe_delete) { Goodcity::UserSafeDelete.new(user) }

  context "if user exists" do
    let(:user) { create(:user) }
    it "should call UserSafeDelete with correct options" do
      expect(Goodcity::UserSafeDelete).to receive(:new).with(user).and_return(user_safe_delete)
      expect(user_safe_delete).to receive("delete!")
      UserSafeDeleteJob.perform_now(user.id)
    end
  end

  context "if user doesn't exist (any more)" do
    it "should not call UserSafeDelete" do
      expect(Goodcity::UserSafeDelete).to_not receive(:new)
      UserSafeDeleteJob.perform_now(1)
    end
  end

  context "if user cannot be deleted" do
    let(:user) { create(:user, :system) }
    it "should send an email" do
      expect { UserSafeDeleteJob.perform_now(user.id) }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

end

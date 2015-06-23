require "rails_helper"

RSpec.describe SendVoicemailJob, type: :job do
  let(:user) { create :user }
  let(:offer) { create :offer, :reviewed, created_by: user }
  let(:record_url) { FFaker::Internet.http_url }

  it "should call SendVoicemailJob with record-link and user-id" do
    User.any_instance.stub(:recent_active_offer_id).and_return(offer.id)

    expect {
      SendVoicemailJob.new.perform(record_url, user.id)
    }.to change(Message.unscoped, :count).by(1)
  end
end

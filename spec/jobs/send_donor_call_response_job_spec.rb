require "rails_helper"

RSpec.describe SendDonorCallResponseJob, type: :job do
  let(:user) { create :user }
  let(:offer) { create :offer, :reviewed, created_by: user }
  let(:record_url) { FFaker::Internet.http_url }

  it "should call SendDonorCallResponseJob with record-link and user-id" do
    allow_any_instance_of(User).to receive(:recent_active_offer_id).
      and_return(offer.id)

    expect {
      SendDonorCallResponseJob.new.perform(user.id, record_url)
    }.to change(Message.unscoped, :count).by(1)
  end
end

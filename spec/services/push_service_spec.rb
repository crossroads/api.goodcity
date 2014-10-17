require "rails_helper"

describe PushService do
  let(:message) { create :message }
  let(:user) { create :user }
  let(:users) { create_list :user, 12 }
  let(:one_channel) { "user_#{ user.id}" }
  let(:event) { "update_store" }
  let(:data)  { Api::V1::MessageSerializer.new(message) }
  let(:multiple_channels) { users.collect{ |k| "user_#{ k.id}" } }
  let(:push_service) { PushService.new(channel: one_channel, event: "update_store", data: data) }

  context "initialization" do
    it "channel" do
      expect(push_service.channel).to eql(one_channel)
    end
    it "event" do
      expect(push_service.event).to eql(event)
    end
    it "data" do
      expect(push_service.data).to eql(data)
    end
  end

  describe "#notify" do
    let(:push_service_no_params) { PushService.new({}).notify }
    it "raise PushServiceError error" do
      expect { push_service_no_params }.to raise_error do |error|
        expect(error.class).to eq(PushService::PushServiceError)
        expect(error.message).to eq("'channel' has not been set")
      end
   end

    it "multiple receipent through pusher" do
      allow(Pusher).to receive(:trigger).twice
      channel = multiple_channels.in_groups_of(10, false)
      expect(multiple_channels).to  be_kind_of(Array)
      expect(multiple_channels.length).to be > 10
      PushService.new(channel: multiple_channels, event: event, data: message).notify
    end

    it "single receipent through pusher" do
      allow(Pusher).to receive(:trigger).with([one_channel], event, message).and_return({})
      expect(one_channel).to be_kind_of(String)
      PushService.new(channel: one_channel, event: event, data: message).notify
    end
  end
end

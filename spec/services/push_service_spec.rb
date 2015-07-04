require "rails_helper"

describe PushService do

  let(:offer) { create :offer }
  let(:user) { create :user }
  let(:one_channel) { "user_#{ user.id}" }
  let(:event) { "update_store" }
  let(:service) { PushService.new }
  let(:data)  { Api::V1::OfferSerializer.new(offer) }

  context "initialization" do
    let(:push_service) { PushService.new(channel: one_channel, event: event, data: offer) }

    it "channel" do
      expect(push_service.channel).to eql(one_channel)
    end
    it "event" do
      expect(push_service.event).to eql(event)
    end
    it "data" do
      expect(push_service.data).to eql(offer)
    end
  end

  describe "notify" do
    let(:push_service_no_params) { PushService.new({}).notify }
    let(:users) { create_list :user, 12 }
    let(:multiple_channels) { users.collect{ |k| "user_#{ k.id}" } }

    it "raise PushServiceError error" do
      expect { push_service_no_params }.to raise_error do |error|
        expect(error.class).to eq(PushService::PushServiceError)
        expect(error.message).to eq("'channel' has not been set")
      end
    end

    it "multiple receipent through pusher" do
      expect(PusherJob).to receive(:perform_later).with(multiple_channels, event, offer.to_json, false)
      PushService.new(channel: multiple_channels, event: event, data: offer).notify
    end

    it "single receipent through pusher" do
      expect(PusherJob).to receive(:perform_later).with([one_channel], event, offer.to_json, false)
      PushService.new(channel: one_channel, event: event, data: offer).notify
    end
  end

  describe "send_new_message_notification" do
    it do
      entity = OpenStruct.new(id:1, dummy: "entity", prop2: "dummy", body: "A notification text string",
        is_private: true, sender_id: 1, offer: OpenStruct.new(id:2))

      expect(service).to receive(:notify)
      expect(AzureNotifyJob).to receive(:perform_later)
      service.send_new_message_notification(channel: [one_channel], message_object: entity)
      expect(service.data[:category]).to eq('message')
      expect(service.data[:message]).to eq('A notification text string')
      expect(service.data[:is_private]).to eq(true)
      expect(service.data[:offer_id]).to eq(2)
      expect(service.data[:item_id]).to eq(nil)
      expect(service.data[:author_id]).to eq(1)
      expect(service.channel).to eq([one_channel])
      expect(service.event).to eq("notification")
    end
  end
end

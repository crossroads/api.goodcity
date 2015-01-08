require "rails_helper"

describe PushService do

  before { allow(Pusher).to receive(:trigger) }
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
      expect(PusherJob).to receive(:perform_later).with(multiple_channels[0..9], event, offer.to_json)
      expect(PusherJob).to receive(:perform_later).with(multiple_channels[10..12], event, offer.to_json)
      PushService.new(channel: multiple_channels, event: event, data: offer).notify
    end

    it "single receipent through pusher" do
      expect(PusherJob).to receive(:perform_later).with([one_channel], event, offer.to_json)
      PushService.new(channel: one_channel, event: event, data: offer).notify
    end
  end

  describe "send_notification" do
    it do
      text = "A notification text string"
      entity_type = "message"
      entity = { dummy: "entity", entity: "dummy"}

      expect(service).to receive(:notify)

      service.send_notification(text: text, entity_type: entity_type, entity: entity, channel: [one_channel])

      expect(service.data[:text]).to eq(text)
      expect(service.data[:entity_type]).to eq(entity_type)
      expect(service.data[:entity].as_json).to eq(entity.as_json)
      expect(service.channel).to eq([one_channel])
      expect(service.event).to eq("notification")
    end
  end
end

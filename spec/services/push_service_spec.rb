require "rails_helper"

describe PushService do

  let(:service) { PushService.new }
  let(:channels) { ['user_1'] }
  let(:admin_channel) { 'user_1_admin' }
  let(:data)    { {message: message} }
  let(:message) { "New message" }
  let(:time)     { Time.now }


  before { allow(Time).to receive(:now).and_return(time) }

  context "send_update_store" do
    context "should send updates" do
      it "with single channel string" do
        expect(SocketioSendJob).to receive(:perform_later).with(['user_1'], 'update_store', data.to_json, false)
        service.send_update_store('user_1', data)
      end
      it "with single channel array" do
        expect(SocketioSendJob).to receive(:perform_later).with(['user_1'], 'update_store', data.to_json, false)
        service.send_update_store(['user_1'], data)
      end
      it "with mixed channel array" do
        expect(SocketioSendJob).to receive(:perform_later).with(['user_1', 'user_2', 'user_3', 'user_4'], 'update_store', data.to_json, false)
        service.send_update_store(['user_1', ['user_2', 'user_3'], 'user_4'], data)
      end
    end
    context "should not send updates" do
      it "if channels are nil" do
        expect(SocketioSendJob).to_not receive(:perform_later)
        service.send_update_store(nil, data)
      end
      it "if channels are []" do
        expect(SocketioSendJob).to_not receive(:perform_later)
        service.send_update_store([], data)
      end
    end
  end

  context "send_notification" do
    let(:payload) { data.merge(date: time).to_json }

    context "donor app" do
      let(:app_name) { DONOR_APP }
      it do
        expect(SocketioSendJob).to receive(:perform_later).with(channels, "notification", payload)
        expect(AzureNotifyJob).to receive(:perform_later).with(channels, data, app_name)
        service.send_notification(channels, app_name, data)
      end
    end

    context "admin app" do
      let(:app_name) { ADMIN_APP }
      it do
        expect(SocketioSendJob).to receive(:perform_later).with([admin_channel], "notification", payload)
        expect(AzureNotifyJob).to receive(:perform_later).with([admin_channel], data, app_name)
        service.send_notification(admin_channel, app_name, data)
      end
    end

  end

end

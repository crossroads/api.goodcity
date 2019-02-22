require "rails_helper"

describe PushService do

  let(:service) { PushService.new }
  let(:channel) { ['user_1'] }
  let(:admin_channel) { 'user_1_admin' }
  let(:data)    { {message: message} }
  let(:message) { "New message" }
  let(:time)     { Time.now }
  
  before { allow(Time).to receive(:now).and_return(time) }

  context "send_update_store" do
    pending "should send updates"
  end

  context "send_notification" do
    
    context "donor app" do
      let(:app_name) { DONOR_APP }
      it do
        payload = data.merge(date: time).to_json
        expect(SocketioSendJob).to receive(:perform_later).with(channel, "notification", payload)
        expect(AzureNotifyJob).to receive(:perform_later).with(channel, data, app_name)
        service.send_notification(channel, app_name, data)
      end
    end

    context "admin app" do
      let(:app_name) { ADMIN_APP }
      it do
        payload = data.merge(date: time).to_json
        expect(SocketioSendJob).to receive(:perform_later).with([admin_channel], "notification", payload)
        expect(AzureNotifyJob).to receive(:perform_later).with([admin_channel], data, app_name)
        service.send_notification(admin_channel, app_name, data)
      end
    end
    
  end

end

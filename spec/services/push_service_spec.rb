require "rails_helper"

describe PushService do

  let(:service) { PushService.new }

  describe "send_notification" do
    it do
      expect(AzureNotifyJob).to receive(:perform_later)
      expect(SocketioSendJob).to receive(:perform_later)

      service.send_notification(["user_1"], true, {})
    end
  end
end

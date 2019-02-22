require 'rails_helper'

context PushUpdatesForSubscription do

  let(:push_service) { PushService.new }
  
  before(:each) do
    allow(PushService).to receive(:new).and_return(push_service)
  end

  context "send_new_message_notification" do

    context "calls Push Service with notification data" do
      let!(:subscription) { create :offer_subscription, user: reviewer }
      let(:reviewer) { create :user, :reviewer }
      let(:reviewer_channel) { ["user_#{reviewer.id}_admin"] }
  
      before(:each) do
        allow(Channel).to receive(:private_channels_for).and_return(reviewer_channel)
        allow(subscription).to receive(:app_name).and_return(ADMIN_APP)
      end
      
      it do
        expect(push_service).to receive(:send_notification) do |channel, app_name, data|
          expect(channel).to eql(reviewer_channel)
          expect(app_name).to eql(ADMIN_APP)
          expect(data[:category]).to eql('message')
          expect(data[:message_id]).to eql(subscription.message.id)
        end
        subscription.send_new_message_notification
      end
    end

    context "doesn't send notification if message sender is recipient" do
      let!(:subscription) { create :offer_subscription }
      let(:donor) { subscription.offer.created_by }
      let(:donor_channel) { "user_#{donor.id}" }
      it do
        expect(push_service).to_not receive(:send_notification).with(donor_channel, DONOR_APP, anything)
        subscription.user = subscription.message.sender = donor
        subscription.send_new_message_notification
      end
    end

  end

  context "app_name" do
    context "with offer subscription" do
      let(:subscription) { create :offer_subscription }
      subject { subscription.send(:app_name) }
      context "donor app" do
        it do
          subscription.user_id = subscription.message.offer.created_by_id
          expect(subject).to eql(DONOR_APP)
        end
      end
      context "admin app" do
        it do
          expect(subject).to eql(ADMIN_APP)
        end
      end
    end

    context "with order subscription" do
      let(:subscription) { create :order_subscription }
      subject { subscription.send(:app_name) }
      context "browse app" do
        it do
          subscription.user_id = subscription.message.order.created_by_id
          expect(subject).to eql(BROWSE_APP)
        end
      end
      context "stock app" do
        it do
          expect(subject).to eql(STOCK_APP)
        end
      end
    end
  end

end
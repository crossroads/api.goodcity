require "rails_helper"

describe Channel do

  context 'channels_for_user_with_app_context' do
  
    subject { Channel.channels_for_user_with_app_context(current_user, app_name) }

    context 'donor app' do
      let(:app_name) { DONOR_APP }
      let(:current_user) { create :user }
      let(:expected_channels) { ["user_#{current_user.id}"] }
      it { expect(subject).to eql(expected_channels) }
    end

    context 'supervisor on admin app' do
      let(:app_name) { ADMIN_APP }
      let(:current_user) { create :user, :supervisor }
      let(:expected_channels) { ["user_#{current_user.id}_admin", 'supervisor'] }
      it { expect(subject).to eql(expected_channels) }
    end

    context 'order_fulfilment on stock app' do
      let(:app_name) { STOCK_APP }
      let(:current_user) { create :user, :order_fulfilment }
      let(:expected_channels) { ["user_#{current_user.id}_stock", 'order_fulfilment'] }
      it { expect(subject).to eql(expected_channels) }
    end

    context 'charity on browse app' do
      let(:app_name) { BROWSE_APP }
      let(:current_user) { create :user, :charity }
      let(:expected_channels) { ["user_#{current_user.id}_browse"] }
      it { expect(subject).to eql(expected_channels) }
    end
  
  end

  context 'add_app_name_suffix' do
    let(:channel_name) { ['user_1', 'reviewer'] }

    context 'donor app' do
      let(:app_name) { DONOR_APP }
      it { expect(Channel.add_app_name_suffix(channel_name, app_name)).to eql(['user_1', 'reviewer']) }
    end

    context 'admin app' do
      let(:app_name) { ADMIN_APP }
      it { expect(Channel.add_app_name_suffix(channel_name, app_name)).to eql(['user_1_admin', 'reviewer']) }
    end

    context 'stock app' do
      let(:app_name) { STOCK_APP }
      it { expect(Channel.add_app_name_suffix(channel_name, app_name)).to eql(['user_1_stock', 'reviewer']) }
    end

    context 'browse app' do
      let(:app_name) { BROWSE_APP }
      it { expect(Channel.add_app_name_suffix(channel_name, app_name)).to eql(['user_1_browse', 'reviewer']) }
    end

    context 'with nil channel name' do
      let(:channel_name) { nil }
      context 'on donor app' do
        let(:app_name) { DONOR_APP }
        it { expect(Channel.add_app_name_suffix(channel_name, app_name)).to eql([]) }
      end
      context 'on admin app' do
        let(:app_name) { ADMIN_APP }
        it { expect(Channel.add_app_name_suffix(channel_name, app_name)).to eql([]) }
      end
    end

    context 'with blank channel name' do
      let(:channel_name) { '' }
      context 'on donor app' do
        let(:app_name) { DONOR_APP }
        it { expect(Channel.add_app_name_suffix(channel_name, app_name)).to eql([]) }
      end
      context 'on admin app' do
        let(:app_name) { ADMIN_APP }
        it { expect(Channel.add_app_name_suffix(channel_name, app_name)).to eql([]) }
      end
    end

  end

  # since these are important channels, we should test for their existence
  context 'reserved channels' do
    
    subject { Channel.send(channel) }
    
    context 'reviewer' do
      let(:channel) { 'reviewer' }
      it { expect(subject).to eql([channel]) }
    end
    context 'supervisor' do
      let(:channel) { 'supervisor' }
      it { expect(subject).to eql([channel]) }
    end
    context 'browse' do
      let(:channel) { 'browse' }
      it { expect(subject).to eql([channel]) }
    end
    context 'order_fulfilment' do
      let(:channel) { 'order_fulfilment' }
      it { expect(subject).to eql([channel]) }
    end
    context "staff" do
      let(:channel) { 'staff' }
      it { expect(subject).to eql(['reviewer', 'supervisor']) }
    end
    context "goodcity_order_channel" do
      let(:channel) { 'goodcity_order_channel' }
      it { expect(subject).to eql(['order_fulfilment']) }
    end
    context "order_channel" do
      let(:channel) { 'order_channel' }
      it { expect(subject).to eql(['reviewer', 'supervisor', 'browse']) }
    end
  end

  context "#user_channels" do
    it "for donor" do
      user = create(:user)
      expect(Channel.user_channels(user)).to eq(["user_#{user.id}"])
    end
    it "for reviewer" do
      user = create(:user, :reviewer)
      expect(Channel.user_channels(user)).to match_array(["user_#{user.id}", "reviewer"])
    end
    it "for supervisor" do
      user = create(:user, :supervisor)
      expect(Channel.user_channels(user)).to match_array(["user_#{user.id}", "supervisor"])
    end
    it "for order_fulfilment" do
      user = create(:user, :order_fulfilment)
      expect(Channel.user_channels(user)).to match_array(["user_#{user.id}", "order_fulfilment"])
    end
  end

end

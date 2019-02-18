require "rails_helper"

describe Channel do

  context 'channels_for' do
  
    subject { Channel.channels_for(user, app_name) }

    context 'donor app' do
      let(:app_name) { DONOR_APP }
      let(:user) { create :user }
      let(:expected_channels) { ["user_#{user.id}"] }
      it { expect(subject).to eql(expected_channels) }
    end

    context 'supervisor on admin app' do
      let(:app_name) { ADMIN_APP }
      let(:user) { create :user, :supervisor }
      let(:expected_channels) { ["user_#{user.id}_admin", 'supervisor'] }
      it { expect(subject).to eql(expected_channels) }
    end

    context 'order_fulfilment on stock app' do
      let(:app_name) { STOCK_APP }
      let(:user) { create :user, :order_fulfilment }
      let(:expected_channels) { ["user_#{user.id}_stock", 'order_fulfilment'] }
      it { expect(subject).to eql(expected_channels) }
    end

    context 'charity on browse app' do
      let(:app_name) { BROWSE_APP }
      let(:user) { create :user, :charity }
      let(:expected_channels) { ["user_#{user.id}_browse", "browse"] }
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
    it { expect(Channel.const_get("REVIEWER_CHANNEL")).to eql('reviewer') }
    it { expect(Channel.const_get("SUPERVISOR_CHANNEL")).to eql('supervisor') }
    it { expect(Channel.const_get("BROWSE_CHANNEL")).to eql('browse') }
    it { expect(Channel.const_get("STOCK_CHANNEL")).to eql('stock') }
    it { expect(Channel.const_get("ORDER_FULFILMENT_CHANNEL")).to eql('order_fulfilment') }
    it { expect(Channel.const_get("STAFF_CHANNEL")).to eql(['reviewer', 'supervisor']) }
    it { expect(Channel.const_get("ORDER_CHANNEL")).to eql(['reviewer', 'supervisor', 'browse']) }
  end

  context "private_channels_for" do
    context "donor on donor app" do
      let(:user) { create :user }
      let(:app_name) { DONOR_APP }
      let(:channels) { ["user_#{user.id}"] }
      it { expect(Channel.private_channels_for(user, app_name)).to eq(channels) }
    end
    context "reviewer"
      let(:user) { create :user, :reviewer }
      let(:channels) { ["user_#{user.id}_#{app_name}"] }
      context "on admin app" do
        let(:app_name) { ADMIN_APP }
        it { expect(Channel.private_channels_for(user, app_name)).to eq(channels) }
      end
      context "on stock app" do
        let(:app_name) { STOCK_APP }
        it { expect(Channel.private_channels_for(user, app_name)).to eq(channels) }
      end
      context "on browse app" do
        let(:app_name) { BROWSE_APP }
        it { expect(Channel.private_channels_for(user, app_name)).to eq(channels) }
      end
    context "order fulfiller on stock app" do
      let(:user) { create :user, :order_fulfilment }
      let(:app_name) { STOCK_APP }
      it { expect(Channel.private_channels_for(user, app_name)).to eq(channels) }
    end
    context "charity on browse app" do
      let(:user) { create :user, :charity }
      let(:app_name) { BROWSE_APP }
      it { expect(Channel.private_channels_for(user, app_name)).to eq(channels) }
    end
    context "with no app_name" do
      let(:user) { create :user, :charity }
      let(:app_name) { nil }
      let(:channels) { ["user_#{user.id}"] }
      it { expect(Channel.private_channels_for(user, app_name)).to eq(channels) }
    end
    context "with mulitple users" do
      let(:users) { create_list :user, 2, :reviewer }
      let(:app_name) { ADMIN_APP }
      let(:channels) { users.map{|user| "user_#{user.id}_#{app_name}" } }
      it { expect(Channel.private_channels_for(users, app_name)).to match_array(channels) }
    end
    context "with no users" do
      let(:users) { nil }
      let(:app_name) { ADMIN_APP }
      let(:channels) { [] }
      it { expect(Channel.private_channels_for(users, app_name)).to match_array(channels) }
    end
    
  end

end

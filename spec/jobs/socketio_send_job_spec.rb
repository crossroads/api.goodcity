require "rails_helper"

context SocketioSendJob, type: :job do

  let(:event) { 'update' }
  let(:data) { {one: 1}.to_json }
  let(:args) { JSON.parse(data) }

  context "should call socketio with options" do
    let(:channels) { ['channel1', 'channel2'] }
    it do
      expect(Nestful).to receive(:post).with(/http/, {rooms: channels, event: event, args: args}, format: :json)
      SocketioSendJob.new.perform(channels, event, data)
    end
  end

  context "should call socketio with options in batches of 20" do
    let(:channels_1_20) { (1..20).map{|c| "channel#{c}"} }
    let(:channels_21_40) { (21..40).map{|c| "channel#{c}"} }
    let(:channels) { channels_1_20 + channels_21_40 }
    it do
      expect(Nestful).to receive(:post).with(/http/, {rooms: channels_1_20, event: event, args: args}, format: :json)
      expect(Nestful).to receive(:post).with(/http/, {rooms: channels_21_40, event: event, args: args}, format: :json)
      SocketioSendJob.new.perform(channels, event, data)
    end
  end

end

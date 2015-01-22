require "rails_helper"

describe PusherJob, :type => :job do

  it "should call twilio with options" do
    channels = ['channel1', 'channel2']
    event = 'update'
    data = {one: 1}.to_json

    expect(Nestful).to receive(:post).with(any_args, {rooms:channels, event:event, args:JSON.parse(data)}, any_args)
    PusherJob.new.perform(channels, event, data)
  end

end

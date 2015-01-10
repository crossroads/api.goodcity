require "rails_helper"

describe PusherJob, :type => :job do

  it "should call twilio with options" do
    expect(Pusher).to receive(:trigger).with(['channel1', 'channel2'], 'update', {one: 1})
    PusherJob.new.perform(['channel1', 'channel2'], 'update', {one: 1})
  end

end

require "rails_helper"

describe AirbrakeJob, :type => :job do

  let(:notice) { "Test airbrake expection" }

  it "should receive a notice and call airbrake" do
    expect(Airbrake).to receive_message_chain(:sender, :send_to_airbrake).with(notice)
    AirbrakeJob.new.perform(notice)
  end

end

class AirbrakeJob  < ActiveJob::Base
  queue_as :airbrake

  def perform(notice)
    Airbrake.sender.send_to_airbrake(notice)
  end
end

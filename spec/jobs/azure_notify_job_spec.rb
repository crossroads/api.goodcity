require "rails_helper"

describe AzureNotifyJob, type: :job do

  let(:channel) { 'user_12_admin' }
  let(:data) { {data: 'data'} }
  let(:app_name) { DONOR_APP }
  let(:azure_notification_service) { AzureNotificationsService.new(app_name) }

  before do
    expect(AzureNotificationsService).to receive(:new).with(app_name).and_return(azure_notification_service)
  end

  it "should call AzureNotificationsService with correct options" do
    expect(azure_notification_service).to receive(:notify).with(channel, data)
    AzureNotifyJob.perform_now(channel, data, app_name)
  end

end

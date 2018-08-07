require "rails_helper"

describe AzureRegisterJob, type: :job do

  let(:handle) { 'deviceID' }
  let(:channel) { 'user_12_admin' }
  let(:platform) { 'gcm'}
  let(:app_name) { DONOR_APP }
  let(:azure_notification_service) { AzureNotificationsService.new(app_name) }

  before do
    expect(AzureNotificationsService).to receive(:new).with(app_name).and_return(azure_notification_service)
  end

  it "should call AzureNotificationsService with correct options" do
    expect(azure_notification_service).to receive(:register_device).with(handle, channel, platform)
    AzureRegisterJob.perform_now(handle, channel, platform, app_name)
  end

end

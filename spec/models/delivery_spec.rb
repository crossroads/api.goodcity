require 'rails_helper'

RSpec.describe Delivery, type: :model do
  describe 'Association' do
    it { is_expected.to belong_to :schedule }
    it { is_expected.to belong_to :offer }
    it { is_expected.to belong_to :contact }
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "successful delivery plan" do
    it "should send notification for new message" do
      delivery = create :drop_off_delivery
      expect(delivery).to receive(:notify_reviewers)
      delivery.update_attributes(schedule_id: (create :drop_off_schedule).id)
    end
  end

end

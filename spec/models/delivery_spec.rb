require 'rails_helper'

RSpec.describe Delivery, type: :model do
  describe 'Association' do
    it { is_expected.to belong_to :schedule }
    it { is_expected.to belong_to :offer }
    it { is_expected.to belong_to :contact }
  end
end

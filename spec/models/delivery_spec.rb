require 'rails_helper'

RSpec.describe Delivery, type: :model do
  describe 'Association' do
    it { should belong_to :schedule }
    it { should belong_to :offer }
    it { should belong_to :contact }
  end
end

require 'rails_helper'

RSpec.describe AppointmentSlot, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:timestamp).of_type(:datetime) }
    it { is_expected.to have_db_column(:quota).of_type(:integer) }
    it { is_expected.to have_db_column(:note).of_type(:string) }
  end
  
end

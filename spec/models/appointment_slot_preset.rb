require 'rails_helper'

RSpec.describe AppointmentSlotPreset, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:day).of_type(:integer) }
    it { is_expected.to have_db_column(:hours).of_type(:integer) }
    it { is_expected.to have_db_column(:minutes).of_type(:integer) }
    it { is_expected.to have_db_column(:quota).of_type(:integer) }
  end
  
end

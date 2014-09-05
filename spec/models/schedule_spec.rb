require 'rails_helper'

RSpec.describe Schedule, type: :model do

  describe 'Association' do
    it { should have_many :deliveries }
  end

  describe 'Database columns' do
    it{ should have_db_column(:resource).of_type(:string)}
    it{ should have_db_column(:slot).of_type(:integer)}
    it{ should have_db_column(:slot_name).of_type(:string)}
    it{ should have_db_column(:zone).of_type(:string)}
    it{ should have_db_column(:scheduled_at).of_type(:datetime)}
  end
end

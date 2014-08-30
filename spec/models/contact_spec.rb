require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'Association' do
    it { should have_one :address }
  end

  describe 'Database columns' do
    it{ should have_db_column(:name).of_type(:string)}
    it{ should have_db_column(:mobile).of_type(:string)}
  end
end

require 'rails_helper'

RSpec.describe Image, type: :model do

  describe 'Associations' do
    it { should belong_to :item }
  end

  describe 'Database Columns' do
    it { should have_db_column(:cloudinary_id).of_type(:string) }
    it { should have_db_column(:favourite).of_type(:boolean) }
    it { should have_db_column(:item_id).of_type(:integer) }
  end
end

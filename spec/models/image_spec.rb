require 'rails_helper'

RSpec.describe Image, type: :model do

  describe 'Associations' do
    it { should belong_to :parent }
  end

  describe 'Database Columns' do
    it { should have_db_column(:order).of_type(:integer) }
    it { should have_db_column(:image).of_type(:string) }
    it { should have_db_column(:favourite).of_type(:boolean) }
    it { should have_db_column(:order).of_type(:integer) }
    it { should have_db_column(:parent_type).of_type(:string) }
    it { should have_db_column(:parent_id).of_type(:integer) }
  end
end

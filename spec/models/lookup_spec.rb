require 'rails_helper'

RSpec.describe Lookup, type: :model do

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:name).of_type(:string)}
    it{ is_expected.to have_db_column(:value).of_type(:string)}
    it{ is_expected.to have_db_column(:label_en).of_type(:string)}
    it{ is_expected.to have_db_column(:label_zh_tw).of_type(:string)}
  end
end

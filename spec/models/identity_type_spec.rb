require 'rails_helper'

RSpec.describe IdentityType, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:name_en).of_type(:string) }
    it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:identifier).of_type(:string) }
  end

end

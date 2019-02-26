require 'rails_helper'

RSpec.describe ProcessChecklist, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:text_en).of_type(:string) }
    it { is_expected.to have_db_column(:text_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:booking_type_id).of_type(:integer) }
  end

end

require 'rails_helper'

RSpec.describe IdentityType, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:name).of_type(:string) }
  end

end

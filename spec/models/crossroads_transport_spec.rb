require 'rails_helper'

RSpec.describe CrossroadsTransport, type: :model do

  it { is_expected.to have_db_column(:name_en).of_type(:string) }
  it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
  it { is_expected.to have_db_column(:cost).of_type(:integer) }
  it { is_expected.to have_db_column(:truck_size).of_type(:float) }

  it { is_expected.to validate_presence_of(:name_en) }

end

require 'rails_helper'

RSpec.describe CrossroadsTransport, type: :model do

  it { should have_db_column(:name_en).of_type(:string) }
  it { should have_db_column(:name_zh_tw).of_type(:string) }
  it { should validate_presence_of(:name_en) }

end

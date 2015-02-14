require 'rails_helper'

RSpec.describe District, :type => :model do

  describe "validations" do

    it { is_expected.to validate_presence_of(:name_en) }
    it { is_expected.to validate_presence_of(:territory_id) }

  end

end

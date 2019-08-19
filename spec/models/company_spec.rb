require 'rails_helper'

RSpec.describe Company, type: :model do
  describe "Associations" do
    it { is_expected.to has_many :offers  }
  end
end

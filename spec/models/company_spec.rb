require 'rails_helper'

RSpec.describe Company, type: :model do
  describe "Associations" do
    it { is_expected.to have_many :offers  }
  end
end

require 'rails_helper'

RSpec.describe Subscription, type: :model do
   describe "Associations" do
    it { is_expected.to belong_to :order }
  end
end

require 'rails_helper'

RSpec.describe Package, :type => :model do
  describe "Associations" do
    it { is_expected.to belong_to :item }
    it { is_expected.to belong_to :package_type }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:package_type_id) }
  end

end

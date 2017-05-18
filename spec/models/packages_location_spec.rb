require 'rails_helper'

RSpec.describe PackagesLocation, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :location }
    it { is_expected.to belong_to :package }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:location_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
  end

  describe 'Validations' do
    it 'validates quantity' do
      is_expected.to_not allow_value(-1).for(:quantity)
      is_expected.to allow_value(rand(1..99999999)).for(:quantity)
    end
  end

  describe '#update_quantity' do
    it 'should update quantity' do
      packages_location = create(:packages_location)
      new_quantity = rand(4)+2
      expect {
        packages_location.update(quantity: new_quantity)

      }.to change(packages_location, :quantity).from(packages_location.quantity).to(new_quantity)
    end
  end
end

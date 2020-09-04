require 'rails_helper'

RSpec.describe Printer, type: :model do
  describe "Associations" do
    it { is_expected.to have_many :users }
    it { is_expected.to belong_to :location }
  end

  describe "Database columns" do
    it { is_expected.to have_db_column(:active).of_type(:boolean) }
    it { is_expected.to have_db_column(:location_id).of_type(:integer) }
    it { is_expected.to have_db_column(:name).of_type(:string) }
    it { is_expected.to have_db_column(:host).of_type(:string) }
    it { is_expected.to have_db_column(:port).of_type(:string) }
    it { is_expected.to have_db_column(:username).of_type(:string) }
    it { is_expected.to have_db_column(:password).of_type(:string) }
  end

  describe "scope: active" do
    let!(:active_printer) { create :printer, :active }
    let!(:inactive_printer) { create :printer }

    it "return records having visible_to_admin as true" do
      active_printers = Printer.active
      expect(active_printers).to include(active_printer)
      expect(active_printers).to_not include(inactive_printer)
    end
  end
end


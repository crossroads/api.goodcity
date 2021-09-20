require 'rails_helper'

RSpec.describe AccessPass, type: :model do
  describe 'Association' do
    it { is_expected.to belong_to :printer }
    it { is_expected.to belong_to :generated_by }
    it { is_expected.to have_many :access_pass_roles }
    it { is_expected.to have_many :roles }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:access_key).of_type(:integer)}
    it{ is_expected.to have_db_column(:generated_by_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:printer_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:generated_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:access_expires_at).of_type(:datetime)}
  end
end

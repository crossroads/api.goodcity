require 'rails_helper'

describe AuthToken, :type => :model do

  describe 'Association' do
    it { should belong_to :user }
  end

  describe 'Database columns' do
    it{ should  have_db_column(:otp_code_expiry).of_type(:datetime)}
    it{ should  have_db_column(:otp_secret_key).of_type(:string)}
    it{ should  have_db_column(:user_id).of_type(:integer)}
  end
end

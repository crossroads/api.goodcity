require 'rails_helper'

RSpec.describe BraintreeTransaction, type: :model do

  it { is_expected.to have_db_column(:transaction_id).of_type(:string) }
  it { is_expected.to have_db_column(:customer_id).of_type(:integer) }
  it { is_expected.to have_db_column(:amount).of_type(:decimal) }
  it { is_expected.to have_db_column(:status).of_type(:string) }

end

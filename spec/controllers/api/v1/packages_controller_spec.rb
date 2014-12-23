require 'rails_helper'

RSpec.describe Api::V1::PackagesController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:offer) { create :offer, created_by: user }
  let(:item)  { create :item, offer: offer }
  let(:package) { create :package, item: item }
  subject { JSON.parse(response.body) }

end

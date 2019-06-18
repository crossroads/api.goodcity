# require 'rails_helper'

# RSpec.describe Api::V1::BrowseController, type: :controller do

#   describe "GET fetch_packages" do
#     let(:parsed_body) { JSON.parse(response.body) }

#     context "returns a list of published packages" do
#       before do
#         3.times { create :browseable_package }
#         create :package
#         get :fetch_packages
#       end

#       it { expect(response.status).to eql(200) }
#       it do
#         expect(parsed_body['package'].size).to eql(3)
#       end

#       it 'searches goods' do
#         3.times { create :browseable_package, notes: "Baby car seats" }
#         create :package
#         expect(Package.count).to eq(8)
#         get :fetch_packages, "searchText": "car"
#         expect(parsed_body['package'].size).to eql(3)
#       end
#     end
#   end
# end

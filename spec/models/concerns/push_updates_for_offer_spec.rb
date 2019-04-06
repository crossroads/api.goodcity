# require 'rails_helper'

# context PushUpdatesForOffer do

#   let!(:offer) { create :offer }
#   let(:operation) { 'create' }
#   let(:data) { {} }
#   let(:donor) { offer.created_by }
#   let(:push_service) { PushService.new }
#   let(:donor_channel) { ["user_#{donor.id}"] }
#   let(:reviewer) { create :user, :reviewer }
#   let(:data) { { item: item_data, sender: sender, operation: operation } }
#   let(:item_data) {}
#   let(:sender) { reviewer }

#   before(:each) do
#     allow(PushService).to receive(:new).and_return(push_service)
#     allow(offer).to receive(:data_updates).and_return(item_data)
#   end

#   context "sends update to donor and reviewer" do
#     context do
#       before(:each) do
#         allow(offer).to receive(:sender).and_return(reviewer) # Bypass user serialization
#       end
#       it do
#         expect(push_service).to receive(:send_update_store) do |channel, data|
#           expect(channel).to eql(donor_channel)
#           expect(data[:sender]).to eq(reviewer)
#         end
#         expect(push_service).to receive(:send_update_store)  do |channel, data|
#           expect(channel).to eql(Channel::STAFF_CHANNEL)
#           expect(data[:sender]).to eq(reviewer)
#         end
#         offer.update_client_store(operation)
#       end
#     end

#     it "with more detailed sender info"

#   end

# end
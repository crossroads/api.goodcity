require 'goodcity/offer_utils'
require "rails_helper"

context Goodcity::OfferUtils do

  let(:first_user) { create :user }
  let(:other_user) { create :user }
  let!(:base_offer) { create :offer, :reviewed, created_by: first_user }
  let!(:other_offer) { create :offer, :reviewed, created_by: first_user }
  let!(:offer_created_by_other_user) { create :offer, :reviewed, created_by: other_user }

  context "Merge two offers into one" do

    context '.merge_offer!' do

      context 'When both offers belongs to same User' do

        context 'When base offer has a valid state' do

          context 'When other offer has a valid state' do
            before do
              create :item, :with_messages, :with_packages, offer: other_offer
              create :version, item: other_offer, related: other_offer
            end

            it 'should successfully merge other offer into base-offer' do
              response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)

              expect(response).to eq(true)
              expect(base_offer).to be_valid
              expect(Offer.where(id: other_offer.id).count).to eq(0)
            end

            it 'reassign other-offer items along with its messages to base-offer' do
              expect(base_offer.items.count).to eq(0)

              response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)

              expect(response).to eq(true)
              expect(base_offer.items.count).to eq(1)
              expect(base_offer.items.last.messages.count).to eq(1)
              expect(Offer.where(id: other_offer.id).count).to eq(0)
            end

            it 'reassign other-offer item packages to base-offer' do
              expect(base_offer.expecting_packages.count).to eq(0)
              expect(other_offer.expecting_packages.count).to be >= 1

              response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)

              expect(response).to eq(true)
              expect(base_offer.expecting_packages.count).to be >= 1
              expect(Offer.where(id: other_offer.id).count).to eq(0)
            end

            it 'reassign other-offer versions to base-offer' do
              expect(Version.where(related_type: "Offer").where(related_id: base_offer.id).count).to eq(0)
              expect(Version.where(related_type: "Offer").where(related_id: other_offer.id).count).to eq(1)

              response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)

              expect(response).to eq(true)
              expect(Version.where(related_type: "Offer").where(related_id: base_offer.id).count).to eq(1)
              expect(Offer.where(id: other_offer.id).count).to eq(0)
            end
          end

          context 'When other offer has invalid state' do
            it 'should not allow to merge two offer' do
              other_offer.receive
              response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)
              expect(response).to eq(false)
            end
          end

        end

        context 'When base offer has invalid state' do
          it 'should not allow to merge two offer' do
            base_offer.receive
            response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)
            expect(response).to eq(false)
          end
        end
      end

      context 'When both offers belongs to different User' do
        it 'should not allow to merge two offer' do
          response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: offer_created_by_other_user.id)
          expect(response).to eq(false)
        end
      end

    end

  end

end

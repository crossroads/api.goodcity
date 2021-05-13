require 'goodcity/offer_utils'
require 'rails_helper'

context Goodcity::OfferUtils do

  let(:first_user) { create :user }
  let(:other_user) { create :user }
  let!(:base_offer) { create :offer, :reviewed, created_by: first_user }
  let!(:other_offer) { create :offer, :reviewed, created_by: first_user }
  let!(:offer_created_by_other_user) { create :offer, :reviewed, created_by: other_user }

  context 'Merge two offers into one' do

    context '.merge_offer!' do

      context 'When both offers belongs to same User' do

        context 'When base offer has a valid state' do

          context 'When other offer has a valid state' do
            before { create :item, :with_messages, offer: other_offer, donor_description: 'Test description' }

            it 'should successfully merge other offer into base-offer' do
              response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)

              expect(response).to eq(true)
              expect(base_offer).to be_valid
              expect(Offer.where(id: other_offer.id).count).to eq(0)
            end

            it 'reassign other-offer items along with its messages to base-offer' do
              other_offer_item_messages = other_offer.items.last.messages.pluck(:body)

              expect {
                Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)
              }.to change(base_offer.items, :count).from(0).to(1)

              expect(base_offer.items.pluck(:donor_description)).to include('Test description')
              expect(base_offer.items.last.messages.pluck(:body)).to match_array(other_offer_item_messages)
            end

            it 'reassign other-offer item packages to base-offer' do
              create :package, item: other_offer.items.last
              other_offer_packages_note = other_offer.expecting_packages.pluck(:notes)

              expect {
                Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)
              }.to change(base_offer.expecting_packages, :count).from(0).to(1)

              expect(base_offer.expecting_packages.pluck(:notes)).to match_array(other_offer_packages_note)
            end

            it 'reassign other-offer versions to base-offer' do
              create :version, item: other_offer, related: other_offer
              other_offer_version_ids = Version.where(related_type: 'Offer').where(related_id: other_offer.id).pluck(:id)

              response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)

              expect(response).to eq(true)
              expect(Version.where(related_type: 'Offer').where(related_id: base_offer.id).pluck(:id)).to match_array(other_offer_version_ids)
            end
          end

          context 'When other offer has invalid state' do
            it 'should not allow to merge two offer' do
              other_offer.receive

              response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)
              expect(response).to eq(false)
            end

            it 'should not copy other-offer items to base-offer' do
              expect {
                Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)
              }.to_not change(base_offer.items, :count)
            end

          end

        end

        context 'When base offer has invalid state' do
          it 'should not allow to merge two offer' do
            base_offer.receive

            response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)
            expect(response).to eq(false)
          end

          it 'should not copy other-offer items to base-offer' do
            expect {
              Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: other_offer.id)
            }.to_not change(base_offer.items, :count)
          end
        end
      end

      context 'When both offers belongs to different User' do
        it 'should not allow to merge two offer' do
          response = Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: offer_created_by_other_user.id)
          expect(response).to eq(false)
        end

        it 'should not copy other-offer items to base-offer' do
          expect {
            Goodcity::OfferUtils.merge_offer!(offer_id: base_offer.id, other_offer_id: offer_created_by_other_user.id)
          }.to_not change(base_offer.items, :count)
        end
      end

    end

  end

end

# frozen_string_literal: true

require 'rails_helper'

module Messages
  describe Channels do
    let(:offer) { create(:offer) }
    let(:user) { create(:user) }
    let(:channel) { Messages::Channels.new(current_user: user, is_private: true, app_name: DONOR_APP, messageable: offer) }

    describe '#initialize' do
      it 'creates instance for variables' do
        expect(channel.current_user).to eq(user)
        expect(channel.messageable).to eq(offer)
        expect(channel.app_name).to eq(DONOR_APP)
        expect(channel.is_private).to be_truthy
      end
    end

    describe '#related_users' do
      let!(:supervisor) { create(:user, :supervisor) }
      let!(:supervisor2) { create(:user, :supervisor) }
      let!(:reviewer) { create(:user, :reviewer) }

      context 'when ADMIN and DONOR app' do
        let!(:donor) { create(:user) }
        let(:offer) { create(:offer, created_by: donor) }

        before do
          create_list(:user, 2, disabled: true)
          create_list(:user, 3, :order_fulfilment)
          create_list(:user, 3, :charity)
        end

        context 'in DONOR channel from DONOR app' do
          it 'fetches users with REVIEWER or SUPERVISOR role' do
            result = Messages::Channels.new(current_user: donor, is_private: false, app_name: DONOR_APP, messageable: offer).related_users

            expected = [supervisor.id, supervisor.full_name], [reviewer.id, reviewer.full_name], [supervisor2.id, supervisor2.full_name]
            expect(result).to include(Hash[expected])
          end

          it 'does not fetch the current user' do
            result = Messages::Channels.new(current_user: donor, is_private: false, app_name: DONOR_APP, messageable: offer).related_users

            expected = [donor.id, donor.full_name]
            expect(result).not_to include(Hash[*expected])
          end

          it 'does not fetch any stock or browse related users' do
            result = Messages::Channels.new(current_user: donor, is_private: false, app_name: DONOR_APP, messageable: offer).related_users

            expected = User.joins(:user_roles).joins(:roles).where(roles: {name: ["Order fulfilment", "Order administrator", 'Charity']}).map { |u| [u.id, u.full_name]}
            expect(result).not_to include(Hash[expected])
          end

          it 'does not fetch any disabled users' do
            result = Messages::Channels.new(current_user: donor, is_private: false, app_name: DONOR_APP, messageable: offer).related_users

            expected = User.where(disabled: true).map { |u| [u.id, u.full_name]}
            expect(result).not_to include(Hash[expected])
          end
        end

        context 'in DONOR channel from ADMIN app' do
          it 'fetches users with REVIEWER and SUPERVISOR role along with donor' do
            result = Messages::Channels.new(current_user: reviewer, is_private: false, app_name: ADMIN_APP, messageable: offer).related_users

            expected = [supervisor.id, supervisor.full_name], [donor.id, donor.full_name], [supervisor2.id, supervisor2.full_name]
            expect(result).to include(Hash[expected])
          end

          it 'does not fetch any stock or browse related users' do
            result = Messages::Channels.new(current_user: reviewer, is_private: false, app_name: ADMIN_APP, messageable: offer).related_users

            expected = User.joins(:user_roles).joins(:roles).where(roles: {name: ["Order fulfilment", "Order administrator", "Charity"]}).map { |u| [u.id, u.full_name] }
            expect(result).not_to include(Hash[expected])
          end

          it 'does not fetch any disabled users' do
            result = Messages::Channels.new(current_user: reviewer, is_private: false, app_name: ADMIN_APP, messageable: offer).related_users

            expected = User.where(disabled: true).map { |u| [u.id, u.full_name] }
            expect(result).not_to include(Hash[expected])
          end
        end

        context 'in ADMIN app for supervisor channel' do
          it 'fetches users with REVIEWER or SUPERVISOR role' do
            result = Messages::Channels.new(current_user: reviewer, is_private: true, app_name: ADMIN_APP, messageable: offer).related_users

            expected = [supervisor.id, supervisor.full_name], [supervisor2.id, supervisor2.full_name]
            expect(result).to include(Hash[expected])
          end

          it 'does not fetch donor who owns the offer' do
            result = Messages::Channels.new(current_user: reviewer, is_private: true, app_name: ADMIN_APP, messageable: offer).related_users

            expected = [offer.created_by.id, offer.created_by.full_name]
            expect(result).not_to include(Hash[*expected])
          end

          it 'does not fetch any stock or browse related users' do
            result = Messages::Channels.new(current_user: reviewer, is_private: true, app_name: ADMIN_APP, messageable: offer).related_users

            expected = User.joins(:user_roles).joins(:roles).where(roles: {name: ["Order fulfilment", "Order administrator", "Charity"]}).map { |u| [u.id, u.full_name] }
            expect(result).not_to include(Hash[expected])
          end

          it 'does not fetch any disabled users' do
            result = Messages::Channels.new(current_user: reviewer, is_private: true, app_name: ADMIN_APP, messageable: offer).related_users

            expected = User.where(disabled: true).map { |u| [u.id, u.full_name] }
            expect(result).not_to include(Hash[expected])
          end
        end
      end

      context 'when STOCK or BROWSE app' do
        let!(:order_fulfilment) { create(:user, :order_fulfilment)}
        let!(:order_administrator) { create(:user, :order_administrator) }
        let!(:charity) { create(:user, :charity) }
        let(:order) { create(:order, created_by: charity)}
        before do
          create_list(:user, 2, disabled: true)
          create_list(:user, 3, :reviewer)
          create_list(:user, 3, :supervisor)
        end

        it 'fetches users with "order fulfilment" or "order administrator" role and charity user' do
          result = Messages::Channels.new(current_user: order_fulfilment, is_private: true, app_name: STOCK_APP, messageable: order).related_users

          expected = [charity.id, charity.full_name], [order_administrator.id, order_administrator.full_name]
          expect(result).to include(Hash[expected])

          result = Messages::Channels.new(current_user: charity, is_private: true, app_name: BROWSE_APP, messageable: order).related_users
          expected = [order_fulfilment.id, order_fulfilment.full_name], [order_administrator.id, order_administrator.full_name]
          expect(result).to include(Hash[expected])
        end

        it 'does not fetch any admin or donor related users' do
          result = Messages::Channels.new(current_user: charity, is_private: true, app_name: BROWSE_APP, messageable: order).related_users
          expected = User.joins(:user_roles).joins(:roles).where(roles: {name: ['Reviewer', 'Supervisor']}).map { |u| [u.id, u.full_name] }
          expect(result).not_to include(Hash[expected])
        end

        it 'does not fetch any disabled users' do
          result = Messages::Channels.new(current_user: charity, is_private: true, app_name: BROWSE_APP, messageable: order).related_users
          expected = User.where(disabled: true).map { |u| [u.id, u.full_name] }
          expect(result).not_to include(Hash[expected])
        end
      end
    end
  end
end

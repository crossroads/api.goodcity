require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe Order, type: :model do

  let(:user) { create :user }

  context "create an order" do
    let(:order) { Order.new }
    it "state should not be blank" do
      expect(order.state).to eql('draft')
    end
  end

  before do
    new_time = Time.local(2008, 9, 1, 12, 0, 0)
    Timecop.freeze(new_time)
  end

  after do
    Timecop.return
  end

  describe "Associations" do
    it { is_expected.to belong_to :detail  }
    it { is_expected.to belong_to :stockit_activity }
    it { is_expected.to belong_to :country }
    it { is_expected.to belong_to :stockit_contact }
    it { is_expected.to belong_to :stockit_organisation }
    it { is_expected.to belong_to :organisation }
    it { is_expected.to belong_to(:created_by).class_name('User') }
    it { is_expected.to belong_to(:processed_by).class_name('User') }

    it { is_expected.to have_many :packages }
    it { is_expected.to have_many(:purposes).through(:orders_purposes) }
    it { is_expected.to have_and_belong_to_many(:cart_packages).class_name('Package')}
    it { is_expected.to have_many :orders_packages }
    it { is_expected.to have_many :orders_purposes }
    it { is_expected.to have_one :order_transport }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:status).of_type(:string)}
    it{ is_expected.to have_db_column(:code).of_type(:string)}
    it{ is_expected.to have_db_column(:detail_type).of_type(:string)}
    it{ is_expected.to have_db_column(:description).of_type(:text)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:purpose_description).of_type(:text)}
    it{ is_expected.to have_db_column(:created_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:updated_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:dispatch_started_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:dispatch_started_by_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:cancelled_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:cancelled_by_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:process_completed_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:process_completed_by_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:processed_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:processed_by_id).of_type(:integer)}
  end

  describe 'state transitions' do

    before { User.current_user = user }

    describe '#start_processing' do
      it 'sets processed_at time and processed_by_id as current user if order is in submitted state' do
        order = create :order, state: 'submitted'
        order.start_processing
        expect(order.reload.processed_at).to eq(Time.now)
        expect(order.reload.processed_by_id).to eq(user.id)
      end

      it 'do not sets processed_at time and processed_by_id as current user if order is not in submitted state' do
        order = create :order, state: 'draft'
        order.start_processing
        expect(order.reload.processed_at).to eq(nil)
        expect(order.reload.processed_by_id).to eq(nil)
      end
    end

    describe '#start_dispatching' do
      it 'sets dispatch_started_at time and dispatch_started_by as current user if order is in awaiting_dispatch state' do
        order = create :order, state: 'awaiting_dispatch'
        order.start_dispatching
        expect(order.reload.dispatch_started_at).to eq(Time.now)
        expect(order.reload.dispatch_started_by_id).to eq(user.id)
      end

      it 'do not sets dispatch_started_at time and dispatch_started_by as current user if order is not in awaiting_dispatch state' do
        order = create :order, state: 'draft'
        order.start_processing
        expect(order.reload.processed_at).to eq(nil)
        expect(order.reload.processed_by_id).to eq(nil)
      end
    end

    describe '#finish_processing' do
      it 'sets process_completed_at time and process_completed_by_id as current user if order is in processing state' do
        order = create :order, state: 'processing'
        order.finish_processing
        expect(order.reload.process_completed_at).to eq(Time.now)
        expect(order.reload.process_completed_by_id).to eq(user.id)
      end

      it 'do not sets process_completed_at time and process_completed_by_id as current user if order is not in processing state' do
        order = create :order, state: 'draft'
        order.finish_processing
        expect(order.reload.process_completed_at).to eq(nil)
        expect(order.reload.process_completed_by_id).to eq(nil)
      end
    end

    describe '#close' do
      it 'sets closed_at time and closed_by_id as current user if order is in dispatching state' do
        order = create :order, state: 'dispatching'
        order.close
        expect(order.reload.closed_at).to eq(Time.now)
        expect(order.reload.closed_by_id).to eq(user.id)
      end

      it 'do not sets closed_at time and closed_by_id as current user if order is not in dispatching state' do
        order = create :order, state: 'draft'
        order.close
        expect(order.reload.closed_at).to eq(nil)
        expect(order.reload.closed_by_id).to eq(nil)
      end
    end

    describe '#reopen' do
      it 'sets dispatch attributes and nullyfies closed_at and closed_by' do
        order = create :order, state: 'closed', closed_at: Time.now, closed_by_id: user.id
        order.reopen
        expect(order.reload.closed_at).to eq(nil)
        expect(order.reload.closed_by_id).to eq(nil)
        expect(order.dispatch_started_by_id).to eq(user.id)
        expect(order.dispatch_started_at).to eq(Time.now)
      end
    end

    describe '#restart_process' do
      it 'resets attributes relatred to process started and process completed if order is in awaiting state' do
        order = create :order, :awaiting_dispatch
        order.restart_process
        expect(order.reload.processed_by_id).to eq(nil)
        expect(order.reload.processed_at).to eq(nil)
        expect(order.reload.process_completed_by_id).to eq(nil)
        expect(order.reload.process_completed_at).to eq(nil)
      end
    end

    describe '#redesignate_cancelled_order' do
      it 'sets processed_at and processed_by columns and nullyfies other order workflow related columns' do
        order = create :order, state: 'cancelled', process_completed_at: Time.now, process_completed_by_id: user.id, cancelled_at: Time.now, cancelled_by_id: user.id,
          dispatch_started_by_id: user.id, dispatch_started_at: Time.now
        order.redesignate_cancelled_order
        expect(order.reload.processed_at).to eq(Time.now)
        expect(order.reload.processed_by_id).to eq(user.id)
        expect(order.reload.process_completed_at).to be_nil
        expect(order.reload.process_completed_by_id).to be_nil
        expect(order.reload.cancelled_at).to be_nil
        expect(order.reload.cancelled_by_id).to be_nil
        expect(order.reload.dispatch_started_by_id).to be_nil
        expect(order.reload.dispatch_started_at).to be_nil
      end
    end

    describe '#cancel' do
      it 'set cancelled_by_id with current_user id and cancelled_at time with current time when in submitted state' do
        order = create :order, state: 'submitted'
        orders_package = create :orders_package, order: order, state: 'designated'
        order.cancel
        expect(order.reload.cancelled_at).to eq(Time.now)
        expect(order.reload.cancelled_by_id).to eq(user.id)
        expect(orders_package.reload.state).to eq('cancelled')
      end

      it 'set cancelled_by_id with current_user id and cancelled_at time with current time when in proceesin state' do
        order = create :order, state: 'processing'
        order.cancel
        expect(order.reload.cancelled_at).to eq(Time.now)
        expect(order.reload.cancelled_by_id).to eq(user.id)
      end

      it 'set cancelled_by_id with current_user id and cancelled_at time with current time when in awaiting_dispatch state' do
        order = create :order, state: 'awaiting_dispatch'
        order.cancel
        expect(order.reload.cancelled_at).to eq(Time.now)
        expect(order.reload.cancelled_by_id).to eq(user.id)
      end

      it 'set cancelled_by_id with current_user id and cancelled_at time with current time when in dispatching state' do
        order = create :order, state: 'dispatching'
        order.cancel
        expect(order.reload.cancelled_at).to eq(Time.now)
        expect(order.reload.cancelled_by_id).to eq(user.id)
      end
    end

    describe '#resubmit' do
      it 'nullyfies all columns related to order workflow if order is in cancelled state' do
        order = create :order, state: 'cancelled', processed_at: Time.now,
        processed_by_id: user.id, process_completed_at: Time.now,
        process_completed_by_id: user.id, cancelled_at: Time.now,
        cancelled_by_id: user.id, dispatch_started_by_id: user.id,
        dispatch_started_at: Time.now
        order.resubmit
        expect(order.reload.processed_at).to be_nil
        expect(order.reload.processed_by_id).to be_nil
        expect(order.reload.process_completed_at).to be_nil
        expect(order.reload.process_completed_by_id).to be_nil
        expect(order.reload.cancelled_at).to be_nil
        expect(order.reload.cancelled_by_id).to be_nil
        expect(order.reload.dispatch_started_by_id).to be_nil
        expect(order.reload.dispatch_started_at).to be_nil
      end
    end

    describe '#dispatch_later' do
      it 'nullyfies dispatch_started_at and dispatch_started_by if order is in dispatching state' do
        order = create :order, state: 'dispatching', dispatch_started_at: Time.now, dispatch_started_by_id: user.id
        order.dispatch_later
        expect(order.reload.dispatch_started_at).to be_nil
        expect(order.reload.dispatch_started_by_id).to be_nil
      end
    end
  end

  describe "Callbacks" do
    let(:order) { create(:order, :with_state_draft, :with_orders_packages) }

    it "Assigns GC Code" do
      expect(order.code).to include("GC-")
    end

    it "Updates orders_packages quantity" do
      order.orders_packages.each do |orders_package|
        expect(orders_package.reload.quantity).to eq(orders_package.package.quantity)
      end
    end
  end

  describe "Update OrdersPackages state" do
    let(:order) { create :order, :with_orders_packages  }
    it "Updates state to designated" do
      order.orders_packages.each do |orders_package|
        orders_package.update_state_to_designated
        expect(orders_package.state).to match("designated")
      end
    end
  end

end

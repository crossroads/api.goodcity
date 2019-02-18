require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe Order, type: :model do
  ALL_ORDER_STATES = ["draft", "submitted", "processing", "awaiting_dispatch", "dispatching", "cancelled", "closed"]
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
    it { is_expected.to belong_to :booking_type }
    it { is_expected.to belong_to :country }
    it { is_expected.to belong_to :stockit_contact }
    it { is_expected.to belong_to :stockit_organisation }
    it { is_expected.to belong_to :organisation }
    it { is_expected.to belong_to :beneficiary }
    it { is_expected.to belong_to :address }
    it { is_expected.to belong_to :district }
    it { is_expected.to belong_to(:created_by).class_name('User') }
    it { is_expected.to belong_to(:processed_by).class_name('User') }

    it { is_expected.to have_many :packages }
    it { is_expected.to have_many :goodcity_requests }
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
    it{ is_expected.to have_db_column(:cancellation_reason).of_type(:text)}
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
    it{ is_expected.to have_db_column(:beneficiary_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:address_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:booking_type_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:staff_note).of_type(:string)}
  end

  describe '.my_orders' do
    let(:user) { create :user, :charity, :with_can_manage_orders_permission }
    let(:supervisor) { create :user, :supervisor, :with_can_manage_orders_permission }
    let(:authorised_by_user) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Supervisor' => ['can_manage_orders']} )}

    ALL_ORDER_STATES.each do |state|
      let(:"authorised_#{state}_order") { create :order, :"with_state_#{state}", created_by: user, authorised_by_id:  supervisor.id }
      let(:"unauthorised_#{state}_order") { create :order, :"with_state_#{state}", created_by: user, authorised_by_id:  nil }
    end

    let!(:orders) { (1..5).map { create :order, :with_orders_packages, :with_state_draft, created_by_id: user.id, authorised_by_id: nil } }
    let(:order_created_by_other_user) { create :order, :with_orders_packages, :with_state_draft, created_by_id: authorised_by_user.id, authorised_by_id: nil }

    before(:each) {
      User.current_user = user
    }

    context "with Logged in User" do
      it "will show orders created_by with that logged_in user only" do
        expect(Order.my_orders.count).to eq(5)
      end

      it "will not show orders created_by by other users" do
        order_created_by_other_user
        expect(Order.my_orders).not_to include(order_created_by_other_user)
      end
    end

    context 'with authorised_by_id' do
      it "will not return authorised draft orders" do
        authorised_draft_order
        expect(Order.my_orders.count).to eq(5)
        expect(Order.my_orders).not_to include(authorised_draft_order)
      end

      it 'returns authorised submitted orders' do
        authorised_submitted_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(authorised_submitted_order)
      end

      it 'returns authorised processing orders' do
        authorised_processing_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(authorised_processing_order)
      end

      it 'returns authorised scheduled orders' do
        authorised_awaiting_dispatch_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(authorised_awaiting_dispatch_order)
      end

      it 'returns authorised dispatch orders' do
        authorised_dispatching_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(authorised_dispatching_order)
      end

      it 'returns authorised closed orders' do
        authorised_closed_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(authorised_closed_order)
      end

      it 'returns authorised cancelled orders' do
        authorised_cancelled_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(authorised_cancelled_order)
      end
    end

    context "without authorised_by_id" do
      it "returns unauthorised draft orders" do
        unauthorised_draft_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(unauthorised_draft_order)
      end

      it 'returns unauthorised submitted orders' do
        unauthorised_submitted_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(unauthorised_submitted_order)
      end

      it 'returns unauthorised processing orders' do
        unauthorised_processing_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(unauthorised_processing_order)
      end

      it 'returns unauthorised scheduled orders' do
        unauthorised_awaiting_dispatch_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(unauthorised_awaiting_dispatch_order)
      end

      it 'returns unauthorised dispatch orders' do
        unauthorised_dispatching_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(unauthorised_dispatching_order)
      end

      it 'returns unauthorised closed orders' do
        unauthorised_closed_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(unauthorised_closed_order)
      end

      it 'returns unauthorised cancelled orders' do
        unauthorised_cancelled_order
        expect(Order.my_orders.count).to eq(6)
        expect(Order.my_orders).to include(unauthorised_cancelled_order)
      end
    end
  end

  describe '.recently_used' do
    let!(:user) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Supervisor' => ['can_manage_orders']} )}

    let!(:user1) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Supervisor' => ['can_manage_orders']} )}
    let(:package1) { create(:package)}
    let!(:order1) { create :order, :with_orders_packages, :with_state_submitted, created_by_id: user.id, submitted_by_id: user.id, status: nil, updated_at: Time.now }
    let!(:version1) {order1.versions.first.update(whodunnit: order1.created_by_id)}

    let!(:order2) { create :order, :with_orders_packages, :with_state_submitted, created_by_id: user.id, submitted_by_id: user.id, status: nil, updated_at: Time.now + 1.hour }
    let!(:version2) {order2.versions.first.update(whodunnit: order2.created_by_id)}

    before(:each) {
      User.current_user = user
    }

    it "will show latest updated order as the first order" do
      order1.update(state: 'processing', processed_by_id: user.id, updated_at: Time.now + 2.day)
      order1.versions.last.update(whodunnit: user.id)
      expect(Order.recently_used(user.id).first.id).to eq(order1.id)
      expect(Order.recently_used(user.id)).to include(order1)
    end

    it "will show top 5 updated orders" do
      expect(Order.recently_used(User.current_user.id).count).to eq(2)
    end

    it "will not show updated position of order if other user has updated the record" do
      expect(Order.recently_used(user.id).first).to eq(order2)
      order1.update(state: 'processing', processed_by_id: user1.id, updated_at: Time.now + 2.day)
      expect(Order.recently_used(user.id).first).to eq(order2)
    end

    it "will not show updated order position if other user has added goodcity request" do
      expect(Order.recently_used(user.id).first).to eq(order2)
      gc_request1 = create :goodcity_request, order_id: order1.id, created_by_id: user1.id, created_at: Time.now+2.hours, updated_at: Time.now+2.hours
      expect(Order.recently_used(user.id).first).to eq(order2)
    end

    it "will show updated order position if loggedin user has added goodcity request" do
      expect(Order.recently_used(user.id).first).to eq(order2)
      gc_request1 = create :goodcity_request, order_id: order1.id, created_by_id: user.id, created_at: Time.now+2.hours, updated_at: Time.now+2.hours
      gc_request1.versions.last.update(whodunnit: user.id)
      expect(Order.recently_used(user.id).first).to eq(order1)
    end

    it "will not show updated order position if other user has added packages in order" do
      expect(Order.recently_used(user.id).first).to eq(order2)
      orders_package1 = create :orders_package, package_id: package1.id, order_id: order1.id, state: "designated", quantity: 1, updated_by_id: user1.id, created_at: Time.now+2.hours, updated_at: Time.now+2.hours
      expect(Order.recently_used(user.id).first).to eq(order2)
    end

    it "will add show updated order position if loggedin user has added packages in order" do
      expect(Order.recently_used(user.id).first).to eq(order2)
      orders_package1 = create :orders_package, package_id: package1.id, order_id: order1.id, state: "designated", quantity: 1, updated_by_id: user.id, created_at: Time.now+2.hours, updated_at: Time.now+2.hours
      expect(Order.recently_used(user.id).first).to eq(order1)
    end

    it "will not show non-logged in users order" do
      expect(Order.recently_used(user1.id).count).to eq(0)
    end

    it "will show logged in users order" do
      expect(Order.recently_used(User.current_user.id).count).to eq(2)
    end

    it "will show only goodcity orders" do
      expect(Order.recently_used(User.current_user.id).map(&:detail_type).uniq.first).to eq("GoodCity")
    end
  end

  describe ".active_orders_count_as_per_priority_and_state" do
    before do
      non_priority_submitted = create :order, state: "submitted", submitted_at: Time.zone.now - 25.hours
      priority_submitted = create :order, state: "submitted", submitted_at: Time.zone.now - 23.hours

      non_priority_processing = create :order, state: "processing", processed_at: Time.zone.now - 25.hours
      priority_processing = create :order, state: "processing", processed_at: Time.zone.now - 23.hours
    end

    context "for Non Priority Orders" do
      it "returns non priority orders hash with state as key and its corresponding count as value" do
        expect(Order.active_orders_count_as_per_priority_and_state(is_priority: false)).to eq(
          {"submitted" => 2, "processing" => 2}
        )
      end
    end

    context "for Priority Orders" do
      it "returns priority orders hash with state as key and its corresponding count as value" do
        expect(Order.active_orders_count_as_per_priority_and_state(is_priority: true)).to eq(
          {"priority_submitted" => 1, "priority_processing" => 2}
        )
      end
    end
  end

  describe 'priority rules' do
    let(:at_6pm_today) { Time.now.in_time_zone.change(hour: 18) }
    let(:at_6pm_yesterday) { at_6pm_today - 24.hours }
    let(:after_6pm_today) { Time.now.in_time_zone.change(hour: 19) }
    let(:after_6pm_yesterday) { after_6pm_today - 24.hours }
    let(:before_6pm_today) { Time.now.in_time_zone.change(hour: 15) }
    let(:before_6pm_yesterday) { before_6pm_today - 24.hours }

    context 'A submitted order' do
      it 'should be prioritised if it was submitted more than 24hours ago' do
        old_order = create :order, state: "submitted", submitted_at: Time.now - 25.hours
        order = create :order, state: "submitted", submitted_at: Time.now - 23.hours
        expect(old_order.is_priority?).to eq(true)
        expect(order.is_priority?).to eq(false)
      end

      it 'should filter prioritised orders if it was submitted more than 24hours ago' do
        create :order, state: "submitted", submitted_at: Time.now - 23.hours
        old_order = create :order, state: "submitted", submitted_at: Time.now - 25.hours
        records = Order.where(state: 'submitted')
        expect(records.count).to eq(2)
        expect(records.priority.count).to eq(1)
        expect(records.priority.first.id).to eq(old_order.id)
      end
    end

    context 'An order under review (aka processing)' do

      after { Timecop.return }

      context 'If we\'re past 6pm' do
        before { Timecop.freeze(after_6pm_today) }

        it 'should be prioritised if process was started before 6pm and hasn\'t finished' do
          order_started_before_6 = create :order, state: "processing", processed_at: before_6pm_today
          order_started_before_6_ytd = create :order, state: "processing", processed_at: before_6pm_yesterday
          order_started_after_6 = create :order, state: "processing", processed_at: after_6pm_today
          expect(order_started_before_6.is_priority?).to eq(true)
          expect(order_started_before_6_ytd.is_priority?).to eq(true)
          expect(order_started_after_6.is_priority?).to eq(false)
        end

        it 'should be filter prioritised orders if process was started before 6pm and hasn\'t finished' do
          order_started_before_6 = create :order, state: "processing", processed_at: before_6pm_today
          order_started_before_6_ytd = create :order, state: "processing", processed_at: before_6pm_yesterday
          create :order, state: "processing", processed_at: after_6pm_today
          records = Order.where(state: 'processing')
          expect(records.count).to eq(3)
          expect(records.priority.count).to eq(2)
          expect(records.priority.map(&:id)).to match_array [
            order_started_before_6.id,
            order_started_before_6_ytd.id
          ]
        end
      end

      context 'If we\'re before 6pm' do
        before { Timecop.freeze(before_6pm_today) }

        it 'should be prioritised if process was started before 6pm the previous day and hasn\'t finished' do
          order_started_before_6 = create :order, state: "processing", processed_at: before_6pm_today
          order_started_before_6_ytd = create :order, state: "processing", processed_at: before_6pm_yesterday
          order_started_after_6_ytd = create :order, state: "processing", processed_at: after_6pm_yesterday
          expect(order_started_before_6_ytd.is_priority?).to eq(true)
          expect(order_started_after_6_ytd.is_priority?).to eq(false)
          expect(order_started_before_6.is_priority?).to eq(false)
        end

        it 'should be filter prioritized orders if process was started before 6pm the previous day and hasn\'t finished' do
          create :order, state: "processing", processed_at: before_6pm_today
          create :order, state: "processing", processed_at: after_6pm_yesterday
          order_started_before_6_ytd = create :order, state: "processing", processed_at: before_6pm_yesterday
          records = Order.where(state: 'processing')
          expect(records.count).to eq(3)
          expect(records.priority.count).to eq(1)
          expect(records.priority.first.id).to eq(order_started_before_6_ytd.id)
        end
      end
    end

    context 'An order awaiting dispatch' do
      let(:transport_before_6) { create :order_transport, scheduled_at: before_6pm_today, timeslot: "3PM" }
      let(:transport_after_6) { create :order_transport, scheduled_at: after_6pm_today, timeslot: "19PM" }

      before {
        Timecop.freeze(at_6pm_today)
      }

      it 'should be prioritised if we\'re past it\'s planned dispatch schedule' do
        priority_order = create :order, state: "awaiting_dispatch", order_transport: transport_before_6
        non_priority_order = create :order, state: "awaiting_dispatch", order_transport: transport_after_6
        expect(priority_order.is_priority?).to eq(true)
        #expect(non_priority_order.is_priority?).to eq(false)
      end

      it 'should filter prioritised orders awaiting dispatch' do
        priority_order = create :order, state: "awaiting_dispatch", order_transport: transport_before_6
        create :order, state: "awaiting_dispatch", order_transport: transport_after_6
        records = Order.where(state: 'awaiting_dispatch')
        expect(records.count).to eq(2)
        expect(records.priority.count).to eq(1)
        expect(records.priority.first.id).to eq(priority_order.id)
      end
    end

    context 'An order is dispatching' do

      context 'If we\'re past 6pm' do
        before { Timecop.freeze(after_6pm_today) }

        it 'should be prioritised if it was started before 6pm' do
          dispatching_started_before_6 = create :order, state: "dispatching", dispatch_started_at: before_6pm_today
          dispatching_started_after_6 = create :order, state: "dispatching", dispatch_started_at: after_6pm_today
          dispatching_started_yesterday = create :order, state: "dispatching", dispatch_started_at: before_6pm_yesterday
          expect(dispatching_started_before_6.is_priority?).to eq(true)
          expect(dispatching_started_yesterday.is_priority?).to eq(true)
          expect(dispatching_started_after_6.is_priority?).to eq(false)
        end

        it 'should filter prioritised orders if it was started before 6pm' do
          create :order, state: "dispatching", dispatch_started_at: after_6pm_today
          dispatching_started_before_6 = create :order, state: "dispatching", dispatch_started_at: before_6pm_today
          dispatching_started_yesterday = create :order, state: "dispatching", dispatch_started_at: before_6pm_yesterday
          records = Order.where(state: 'dispatching')
          expect(records.count).to eq(3)
          expect(records.priority.count).to eq(2)
          expect(records.priority.map(&:id)).to match_array([
            dispatching_started_yesterday.id,
            dispatching_started_before_6.id
          ])
        end
      end

      context 'If we\'re before 6pm' do
        before { Timecop.freeze(before_6pm_today) }

        it 'should be prioritised if it was started before 6pm the previous day' do
          dispatching_started_before_6 = create :order, state: "dispatching", dispatch_started_at: before_6pm_today
          dispatching_started_yesterday = create :order, state: "dispatching", dispatch_started_at: before_6pm_yesterday
          expect(dispatching_started_before_6.is_priority?).to eq(false)
          expect(dispatching_started_yesterday.is_priority?).to eq(true)
        end

        it 'should filter prioritised orders if it was started before 6pm the previous day' do
          create :order, state: "dispatching", dispatch_started_at: before_6pm_today
          dispatching_started_yesterday = create :order, state: "dispatching", dispatch_started_at: before_6pm_yesterday
          records = Order.where(state: 'dispatching')
          expect(records.count).to eq(2)
          expect(records.priority.count).to eq(1)
          expect(records.priority.first.id).to eq(dispatching_started_yesterday.id)
        end
      end
    end
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

  describe '#send_new_order_confirmed_sms_to_charity' do
    let(:charity) { create(:user, :charity) }
    let(:supervisor) { create(:user, :supervisor) }
    let(:order) { build(:order, submitted_by: supervisor, created_by: charity) }
    let(:twilio)     { TwilioService.new(charity) }

    it "send order submission sms to charity user who submitted order" do
      expect(TwilioService).to receive(:new).with(charity).and_return(twilio)
      expect(twilio).to receive(:order_confirmed_sms_to_charity).with(order)
      order.send_new_order_confirmed_sms_to_charity
    end
  end

  describe 'Order filtering rules' do
    before do
      create :order, state: "submitted", description: "A table", submitted_at: Time.now - 25.hours
      create :order, state: "submitted", description: "Another table", submitted_at: Time.now - 25.hours
      create :order, state: "submitted", description: "A dangerous weapon", submitted_at: Time.now - 25.hours
      create :order, state: "processing", description: "A chair", processed_at: Time.now - 25.hours
      create :order, state: "processing", description: "A third table", processed_at: Time.now - 25.hours
      create :order, state: "closed", description: "A trampoline", closed_at: Time.now - 25.hours
    end

    it 'Should allow filtering a scoped relation' do
      expect(Order.count).to eq(6)
      expect(Order.where("description ILIKE '%table%'").count).to eq(3)
      expect(Order.where("description ILIKE '%table%'").filter(states: ['submitted']).count).to eq(2)
    end

    it 'Should allow filtering an unscoped relation' do
      expect(Order.count).to eq(6)
      expect(Order.filter(states: ['submitted', 'closed']).count).to eq(4)
    end

    it 'Should allow chaining a scope' do
      expect(Order.count).to eq(6)
      expect(Order.filter(states: ['submitted']).where("description ILIKE '%table%'").count).to eq(2)
    end

    it 'Should not filter out anything if no explicit arguments are provided' do
      expect(Order.count).to eq(6)
      expect(Order.where("description ILIKE '%table%'").count).to eq(3)
      expect(Order.where("description ILIKE '%table%'").filter().count).to eq(3)
    end
  end
end

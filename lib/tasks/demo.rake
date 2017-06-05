require 'factory_girl'

# Run following rake tasks in sequence:
#   rake db:seed
#   rake goodcity:populate_organisations
#   rake stockit:sync
#   rake goodcity:add_stockit_user (paste token in to Stockit secrets.yml)
#   rake demo:load
#     - use 'rake demo:load n' to create n(only integers) record of each model (default n = 10)
namespace :demo do
  unless ENV['LIVE'] == "true"
    task load: :environment do
      puts "This will generate #{count} record of Users, Offers, Packages, OrdersPackages, Orders, Contacts & Organisations"
      create_offers
      create_orders
      create_contacts
      add_organisations_users(4)
    end

    def create_offers
      puts "Offers:\tCreating #{count} submitted, #{count} under_review, #{count} reviewed, #{count} scheduled , #{count} closed, #{count} receiving, #{count} received Offers"
      count.times do
        offer = create_submitted_offer
        puts "\t\tCreated Offer #{offer.id} in 'submitted' state"
        offer = create_reviewing_offer
        puts "\t\tCreated Offer #{offer.id} in 'under_review' state"
        offer = create_reviewed_offer
        puts "\t\tCreated Offer #{offer.id} in 'reviewed' state"
        offer = create_scheduled_offer
        puts "\t\tCreated Offer #{offer.id} in 'scheduled' state"
        offer = create_closed_offer
        puts "\t\tCreated Offer #{offer.id} in 'closed' state"
        offer = create_inactive_offer
        puts "\t\tCreated Offer #{offer.id} in 'inactive' state"
        offer = create_receiving_offer
        puts "\t\tCreated Offer #{offer.id} in 'receiving' state"
        offer = create_recieved_offer
        puts "\t\tCreated Offer #{offer.id} in 'received' state"
      end
    end

    def create_orders
      puts "Orders:\tCreating #{count} designated and #{count} dispatched order with orders_packages "
      count.times do
        create_designated_packages
        puts "\t\tCreated Order #{Order.last.id} with packages in Designated State"
        create_dispatched_packages
        puts "\t\tCreated Order #{Order.last.id} with packages in Dispatched State"
      end
    end

    def create_submitted_offer
      FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor).tap(&:submit)
    end

    def create_reviewing_offer
      User.current_user = reviewer
      create_submitted_offer.tap(&:start_review)
    end

    def create_reviewed_offer
      offer = create_reviewing_offer
      offer.update(reviewed_by: reviewer)
      offer.reload.items.each do |item|
        item.accept
      end
      offer.tap(&:finish_review)
    end

    def create_scheduled_offer
      offer = create_reviewed_offer.tap(&:schedule)
      delivery_type = ["crossroads_delivery", "drop_off_delivery"].sample.to_sym
      FactoryGirl.create(delivery_type, offer: offer)
      offer
    end

    def create_inactive_offer
      create_reviewing_offer.tap(&:mark_inactive)
    end

    def create_closed_offer
      create_reviewed_offer.tap(&:mark_unwanted)
    end

    def create_receiving_offer
      create_reviewed_offer.tap(&:start_receiving)
    end

    def create_recieved_offer
      inventory_offer_packages(create_receiving_offer).tap(&:receive)
    end

    def inventory_offer_packages(offer)
      offer.reload.items.each do |item|
        item.accept
        item.packages.each do |package|
          location_id = Location.pluck(:id).sample
          package.update(inventory_number: InventoryNumber.available_code, allow_web_publish: true, location_id: location_id)
          package.build_or_create_packages_location(location_id, 'create')
          package.mark_received
        end
      end
      offer.update(delivered_by: FactoryGirl.generate(:delivered_by))
      offer
    end

    def create_single_order
      FactoryGirl.create(:order, :with_status_processing, :with_created_by, processed_by: reviewer, organisation: create_organisation)
    end

    def create_designated_packages
      order = create_single_order
      offer = create_recieved_offer
      orders_packages_ids = []
      offer.reload.items.each do |item|
        item.packages.each do |pkg|
          pkg.designate_to_stockit_order(order.id)
          params = {
            order_id: order.id,
            package_id: pkg.id,
            quantity: pkg.quantity
          }
          orders_package = OrdersPackage.add_partially_designated_item(params)
          orders_packages_ids << orders_package.id
        end
      end
      orders_packages_ids
    end

    def create_dispatched_packages
      orders_packages_ids = create_designated_packages
      orders_packages_ids.each do |orders_pkg|
        orders_package = OrdersPackage.find(orders_pkg)
        pkg = orders_package.package
        orders_package.dispatch_orders_package
        pkg.dispatch_stockit_item(orders_package)
      end
      orders_packages_ids
    end

    def create_contacts
      puts "Contacts:\t\tCreating #{count} contacts"
      #create contact
      count.times do
        FactoryGirl.create(:contact)
      end
    end

    def add_organisations_users(count)
      count.times do |i|
        org = FactoryGirl.create(:organisation)
        user = FactoryGirl.create(:user, mobile: "+8525500000"+(i+1).to_s)
        FactoryGirl.create(:organisations_user, organisation: org, user: user, role: "Staff")
      end

    end

    def create_organisation
      Organisation.find(rand(Organisation.count))
    end

    def reviewer
      User.where(permission_id: 3).sample||FactoryGirl.create(:user, :reviewer)
    end

    # Choose a donor from seed data
    def donor
      mobile = ["+85251111111", "+85251111112", "+85251111113", "+85251111114"].sample
      User.find_by_mobile(mobile)
    end


    # Specify number of test cases to produce
    def count
      @count ||= begin
        ARGV.each { |a| task a.to_sym do ; end }
        Integer(ARGV[1]) rescue 0 >0 ? ARGV[1].to_i : 10
      end
      @count
    end
  end
end

require 'factory_bot'

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
      actions = %w(create_submitted_offer create_reviewing_offer create_reviewed_offer
         create_scheduled_offer create_closed_offer create_inactive_offer 
         create_receiving_offer create_received_offer)
      actions.each do |action|
        puts "Creating #{count} #{action}"
        count.times { send(action) }
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
      FactoryBot.create(:offer, :submitted, :with_demo_items, :with_messages, created_by: donor)
    end

    def create_reviewing_offer
      FactoryBot.create(:offer, :under_review, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer)
    end

    def create_reviewed_offer
      FactoryBot.create(:offer, :reviewed, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer)
    end

    def create_scheduled_offer
      FactoryBot.create(:offer, :scheduled, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer)
    end

    def create_inactive_offer
      FactoryBot.create(:offer, :inactive, :with_demo_items, :with_messages, created_by: donor)
    end

    def create_closed_offer
      FactoryBot.create(:offer, :closed, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer, closed_by: reviewer)
    end

    def create_cancelled_offer
      FactoryBot.create(:offer, :cancelled, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer)
    end

    def create_receiving_offer
      FactoryBot.create(:offer, :receiving, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer, received_by: reviewer)
    end

    def create_received_offer
      offer = FactoryBot.create(:offer, :receiving, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer, received_by: reviewer)
      inventory_offer_packages(offer)
    end

    def inventory_offer_packages(offer)
      offer.reload.items.each do |item|
        item.accept
        item.packages.each do |package|
          location_id = Location.pluck(:id).sample
          package.update(inventory_number: InventoryNumber.next_code, allow_web_publish: true, location_id: location_id)
          package.build_or_create_packages_location(location_id, 'create')
          package.mark_received
        end
      end
      offer.update(delivered_by: FactoryBot.generate(:delivered_by))
    end

    def create_single_order
      FactoryBot.create(:order, :with_status_processing, :with_created_by, processed_by: reviewer, organisation: create_organisation)
    end

    def create_designated_packages
      order = create_single_order
      offer = create_received_offer
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
        FactoryBot.create(:contact)
      end
    end

    def add_organisations_users(count)
      count.times do |i|
        org = FactoryBot.create(:organisation)
        user = FactoryBot.create(:user, mobile: "+8525500000"+(i+1).to_s)
        FactoryBot.create(:organisations_user, organisation: org, user: user, role: "Staff")
      end

    end

    def create_organisation
      Organisation.find(Organisation.pluck(:id).sample)
    end

    def reviewer
      User.reviewers.sample || FactoryBot.create(:user, :reviewer)
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

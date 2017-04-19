require 'factory_girl'

# run following rakes in sequence
# rake db:seed
# rake goodcity:update_package_type_description
# rake goodcity:update_package_type_default_location
# rake stockit:add_stockit_locations
# rake stockit:add_stockit_codes
# rake goodcity:update_packages_grade_condition
# rake goodcity:update_package_image
# use 'rake demo:load n' to create n(only integers) record of each model
namespace :demo do
  unless ENV['LIVE'] == "true"
    task load: :environment do
      puts "This will generate #{count} record of Users, Offers, Packages, OrdersPackages, Orders, Contacts & Organisations"
      create_offers
      create_orders
      create_contacts
      create_organizations
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
      puts "Orders:\tCreating #{count} designated and #{count} dispatached order with orders_packages "
      count.times do
        create_designated_packages
        puts "Orders:\t\t#{Order.last.id} Created #{count} Orders in Designated State"
        create_dispatched_packages
        puts "Orders:\t\t#{Order.last.id} Created #{count} Orders in Designated State"
      end
    end

    def create_submitted_offer
      offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
      offer.submit
      offer
    end

    def create_reviewing_offer
      offer = create_submitted_offer
      reviewer = FactoryGirl.create(:user, :reviewer)
      User.current_user = reviewer
      offer.start_review
      offer
    end

    def create_reviewed_offer
      offer = create_reviewing_offer
      offer.finish_review
      offer
    end

    def create_scheduled_offer
      offer = create_reviewed_offer
      offer.schedule
      offer
    end

    def create_inactive_offer
      offer = create_reviewing_offer
      offer.mark_inactive
      offer
    end

    def create_closed_offer
      offer = create_reviewed_offer
      offer.mark_unwanted
      offer
    end

    def create_receiving_offer
      offer = create_reviewed_offer
      offer.start_receiving
      offer
    end

    def create_recieved_offer
      offer = create_receiving_offer
      offer = inventory_offer_packages (offer)
      offer.receive
      offer
    end

    def inventory_offer_packages (offer)
      offer.reload.items.each do |item|
        item.accept
        item.packages.each do |package|
          loc = Location.all.to_a.sample.id
          package.update(inventory_number: InventoryNumber.available_code, allow_web_publish: true, location_id: loc)
          package.build_or_create_packages_location(loc, 'create')

          package.mark_received
        end
      end
      offer.update(delivered_by: ['Gogovan','Crossroads truck','Dropped off'].sample)
      offer
    end

    def create_single_order
      organisation = FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)))
      processor = FactoryGirl.create(:user, :reviewer)
      order = FactoryGirl.create(:order, :with_created_by, processed_by: processor, organisation: organisation)
      order
    end


    def create_designated_packages
      order = create_single_order
      order.save
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

    def create_organizations
      puts "Organisation:\t\tCreating #{count} organizations"
      count.times do
        FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)))
      end
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
        Integer(ARGV[1]) rescue 0 >0 ? ARGV[1].to_i : 1
      end
      @count
    end
  end
end

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
      # puts "Offers:\t\t\tCreating #{count} draft offers, #{count} submitted, #{count} under_review, #{count} reviewed, #{count} scheduled (with_transport), #{count} closed(with_transport)"
      count.times do
        # for submit state
        offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
        offer.submit
        puts "Created Offer in 'submitted' state"

        # for under_review state
        offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
        offer.submit
        offer.start_review
        puts "Created Offer in 'under_review' state"

        # for reviewed state
        offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
        offer.submit
        offer.start_review
        offer.finish_review
        puts "Created Offer in 'reviewed' state"

        # for scheduled state
        offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
        offer.submit
        offer.start_review
        offer.finish_review
        offer.schedule
        puts "Created Offer in 'scheduled' state"

        #for closed state
        offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
        offer.submit
        offer.start_review
        offer.finish_review
        offer.mark_unwanted
        puts "Created Offer in 'closed' state"


        # for inactive state
        offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
        offer.submit
        offer.start_review
        offer.mark_inactive
        puts "Created Offer in 'inactive' state"


        # for receiving state
        offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
        offer.submit
        offer.start_review
        offer.finish_review
        offer.start_receiving
        puts "Created Offer in 'submitted' state"


        # for received state
        (1..2).to_a.each do |a|
          create_recieved_offer

        end
      end
    end

    def create_recieved_offer
      offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
      reviewer = FactoryGirl.create(:user, :reviewer)
      offer.submit
      User.current_user = reviewer
      offer.start_review
      # trans = FactoryGirl.create(:gogovan_transport)
      offer.finish_review
      offer.start_receiving
      offer.reload
      offer.items.all.each do |item|
        item.accept
        item.packages.all.each do |package|
          loc = Location.all.to_a.sample.id
          package.update(inventory_number: InventoryNumber.available_code, allow_web_publish: true, location_id: loc)
          package.build_or_create_packages_location(loc, 'create')

          package.mark_received
        end
      end

      offer.update(delivered_by: ['Gogovan','Crossroads truck','Dropped off'].sample)
      offer.receive
      puts "Created Offer in 'received' state(allow_web_publish)"
      offer
    end

    def create_single_order
        @organisation = FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)))
        @processor = FactoryGirl.create(:user, :reviewer)
        @order = FactoryGirl.create(:order, :with_created_by, processed_by: @processor, organisation: @organisation)
        @order
    end


    def create_designated_packages
      order = create_single_order
      offer = create_recieved_offer
      orders_packages_ids = []
      offer.items.all.each do |item|
        item.packages.all.each do |pkg|
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
      puts "Created Order with Packages in designated state"
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
      puts "Created Order with Packages in dispatched state"
      orders_packages_ids
    end

    def create_orders
      puts "Orders:\t\t\tCreating #{count} Orders along with StockitLocalOrder"
      #create Orders along with StockitLocalOrder

      create_designated_packages
      create_dispatched_packages



      # count.times do
        # create_recieved_offer
        # order = create_single_order
        # pkg = Package.where(state: "received", order_id: nil).first
        # qty = pkg.quantity

        # package = {
        #   order_id: order.id,
        #   package_id: pkg.id,
        #   quantity: pkg.quantity
        # }
        #  require 'rails/commands/server'
        #  "http://#{Rails::Server.new.options[:Host]}:#{Rails::Server.new.options[:Port]}"
        # params = { package: package, id: pkg.id }
        # app.put "/api/v1/items/#{pkg.id}/designate_partial_item", params
      # end
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

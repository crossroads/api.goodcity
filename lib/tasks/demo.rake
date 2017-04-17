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
      # create_package
      # create_orders_packages
      # create_orders
      # create_contacts
      # create_organizations
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
        (1..3).to_a.each do |a|
          offer = FactoryGirl.create(:offer, :with_demo_items, :with_messages, created_by: donor)
          reviewer = FactoryGirl.create(:user, :reviewer)
          offer.submit
          User.current_user = reviewer
          offer.start_review
          # trans = FactoryGirl.create(:gogovan_transport)
          offer.finish_review
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
        end
      end
    end

    def create_package
      # Create Packages for Goodcity and Items for Stockit
      puts "Package:\t\tCreating #{count} Packages for Goodcity and Items for Stockit(with_item, with_set_item, received(published and unpublished) & stockit_package"

      count.times do
        FactoryGirl.create(:package, :with_item, :package_with_locations, :with_inventory_number)
      end
      count.times do
        FactoryGirl.create(:package, :stockit_package, :with_inventory_number , :package_with_locations)
      end
      count.times do
        FactoryGirl.create(:package, :with_set_item, :package_with_locations)
      end
      count.times do
        FactoryGirl.create(:package, :received, :with_inventory_number)
      end
      count.times do
        FactoryGirl.create(:package, :received, :with_inventory_number, :published)
      end
    end

    def create_single_order
        @organisation = FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)))
        @processor = FactoryGirl.create(:user, :reviewer)
        FactoryGirl.create(:order, :with_created_by, processed_by: @processor, organisation: @organisation)
    end

    def create_orders_packages
      puts "OrdersPackage:\t\tCreating #{count} OrdersPackages"
      #create OrdersPackages
      count.times do
        @updated_by  =  FactoryGirl.create(:user, :reviewer)
        @order = create_single_order
        @package = FactoryGirl.create(:package, :with_item, :package_with_locations)
        @orders_package = FactoryGirl.build(:orders_package,
          package: @package,
          order: @order,
          quantity: @package.quantity,
          updated_by: @updated_by
        )
        if(@orders_package.state == "designated")
          @package.order_id = @order_id
        end
        @orders_package.save
      end
    end

    def create_orders
      puts "Orders:\t\t\tCreating #{count} Orders along with StockitLocalOrder"
      #create Orders along with StockitLocalOrder
      count.times do
        create_single_order
      end
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
        Integer(ARGV[1]) rescue 0 >0 ? ARGV[1].to_i : 10
      end
      @count
    end
  end
end

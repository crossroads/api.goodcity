module Goodcity
  # ----------------------------
  # Demo data generator
  # ----------------------------
  
  class DemoData

    DONOR_MOBILES = ["+85251111111", "+85251111112", "+85251111113", "+85251111114"]
    REVIEWER_MOBILES = ["+85261111111", "+85261111112", "+85261111113", "+85261111114"]
    SUPERVISOR_MOBILES = ["+85291111111", "+85291111112", "+85291111113", "+85291111114"]
    CHARITY_MOBILES = ["+85252222221", "+85252222222", "+85252222223", "+85252222224"]
    ORDER_FULFILMENT_MOBILES = ["+85262222221", "+85262222222", "+85262222223", "+85262222224"]
    ORDER_ADMINISTRATOR_MOBILES = ["+85263333331", "+85263333332", "+85263333333", "+85263333334"]
    STOCK_FULFILER_MOBILES = ["+85264444441", "+85264444442", "+85264444443", "+85264444444"]
    STOCK_ADMINISTRATOR_MOBILES = ["+85265555551", "+85265555552", "+85265555553", "+85265555554"]

    attr_accessor :multiple

    def initialize(options = {})
      @multiple = options[:multiple] || 1
    end

    def generate!
      create_organisations
      create_contacts
      create_users
      create_offers
      create_orders
      create_inventory
      create_stocktakes
    end

    private

    ############################## Offers ##############################
  
    def create_offers
      print "Creating #{multiple * 7} offers"
      multiple.times do
        FactoryBot.create(:offer, :submitted, :with_demo_items, :with_messages, created_by: donor); print '.'
        FactoryBot.create(:offer, :under_review, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer); print '.'
        FactoryBot.create(:offer, :reviewed, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer); print '.'
        FactoryBot.create(:offer, :scheduled, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer); print '.'
        FactoryBot.create(:offer, :inactive, :with_demo_items, :with_messages, created_by: donor); print '.'
        FactoryBot.create(:offer, :closed, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer, closed_by: reviewer); print '.'
        FactoryBot.create(:offer, :receiving, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer, received_by: reviewer); print '.'
        create_received_offer; print '.'
      end
      puts
    end
  
    def create_received_offer
      offer = FactoryBot.create(:offer, :receiving, :with_demo_items, :with_messages, created_by: donor, reviewed_by: reviewer, received_by: reviewer)
      inventory_offer_packages(offer)
      offer
    end
  
    def inventory_offer_packages(offer)
      offer.reload.items.each do |item|
        item.accept
        item.packages.each do |package|
          location_id = Location.pluck(:id).sample
          package.update(inventory_number: InventoryNumber.next_code, allow_web_publish: true, location_id: location_id)
          Package::Operations.inventorize(package, location_id)
          package.mark_received
        end
      end
      offer.update(delivered_by: ['Gogovan','Crossroads truck','Dropped off'].sample)
    end

    ############################## Orders ##############################
  
    def create_orders
      print "Creating #{multiple * 6} orders"
      multiple.times do
        FactoryBot.create(:appointment, :with_orders_packages, :with_state_submitted, :with_goodcity_requests, :with_order_transport_self, created_by: charity_user, processed_by: order_reviewer); print '.'
        FactoryBot.create(:appointment, :with_designated_orders_packages, :with_state_processing, :with_goodcity_requests, :with_order_transport_self, created_by: charity_user, processed_by: order_reviewer); print '.'
        FactoryBot.create(:appointment, :with_dispatched_orders_packages, :with_state_dispatching, :with_goodcity_requests, :with_order_transport_self, created_by: charity_user, processed_by: order_reviewer); print '.'
  
        FactoryBot.create(:online_order, :with_orders_packages, :with_state_submitted, :with_goodcity_requests, :with_order_transport_ggv, created_by: charity_user, processed_by: order_reviewer); print '.'
        FactoryBot.create(:online_order, :with_designated_orders_packages, :with_state_processing, :with_goodcity_requests, :with_order_transport_ggv, created_by: charity_user, processed_by: order_reviewer); print '.'
        FactoryBot.create(:online_order, :with_dispatched_orders_packages, :with_state_dispatching, :with_goodcity_requests, :with_order_transport_ggv, created_by: charity_user, processed_by: order_reviewer); print '.'
      end
      puts

      # large qty order
      # create large quantity package, designate 90% to orders (1 per order)
      quantity = 100
      print "Creating large quantity package and designating to #{(quantity * 0.9).to_i} orders"
      donor_condition = DonorCondition.order(Arel.sql('RANDOM()')).first
      package = FactoryBot.create(:package, :received, :with_item, received_quantity: quantity) # inventorized
      (quantity * 0.9).to_i.times do
        order = FactoryBot.create(:online_order, :with_state_processing, created_by: charity_user, processed_by: order_reviewer)
        Package::Operations.designate(package, quantity: 1, to_order: order)
        print '.'
      end
      puts
    end
  
    def choose_organisation
      Organisation.find(Organisation.pluck(:id).sample)
    end
  
    def create_visit
      FactoryBot.create(:order_transport, transport_type: "self")
    end
  
    def create_ggv_transport
      FactoryBot.create(:order_transport, transport_type: "ggv")
    end

    ############################## Inventory ##############################

    def create_inventory
      demo_images = FactoryBot.generate(:cloudinary_demo_images)
      print "Creating #{demo_images.size * multiple} inventory packages"
      multiple.times do
        demo_images.each do |image_key, attrs|
          quantity = rand(1..10)
          package_type = PackageType.find_by_code(attrs[:package_type_name])
          package = FactoryBot.create(:package, :received, :with_item, received_quantity: quantity, package_type: package_type, notes: attrs[:donor_description]) # inventorized
          package.images << FactoryBot.create(:image, image_key, favourite: true)
          print '.'
        end
      end
      puts
    end

    ############################## Users ##############################
  
    def create_users
      roles_and_mobiles = {
        donor: DONOR_MOBILES,
        reviewer: REVIEWER_MOBILES,
        supervisor: SUPERVISOR_MOBILES, 
        charity: CHARITY_MOBILES,
        order_fulfilment: ORDER_FULFILMENT_MOBILES,
        order_administrator: ORDER_ADMINISTRATOR_MOBILES,
        stock_fulfilment: STOCK_FULFILER_MOBILES,
        stock_administrator: STOCK_ADMINISTRATOR_MOBILES }
  
      print "Creating #{roles_and_mobiles.values.sum{|v| v.size}} users"
  
      roles_and_mobiles.each do |role, mobiles|
        mobiles.each do |mobile|
          last_name = FFaker::Name.last_name.dup << mobile[4,2] << mobile.last # Dillion561
          FactoryBot.create(:user, role, last_name: last_name, mobile: mobile)
          print '.'
        end
      end
      puts
    end

    def create_organisations
      print "Creating #{multiple} organisations"
      multiple.times do
        FactoryBot.create(:organisation)
        print '.'
      end
      puts
    end
  
    def create_contacts
      print "Creating #{multiple} contacts"
      multiple.times do
        FactoryBot.create(:contact)
        print '.'
      end
      puts
    end

    def reviewer
      User.reviewers.sample # || FactoryBot.create(:user, :reviewer)
    end
  
    def order_reviewer
      User.order_fulfilments.sample
    end
  
    def donor
      User.find_by_mobile(DONOR_MOBILES.sample)
    end
  
    def charity_user
      User.find_by_mobile(CHARITY_MOBILES.sample)
    end
  
    def stock_administrator
      User.stock_administrators.sample
    end
  
    ############################## Stocktakes ##############################
    def create_stocktakes
      # Stocktake half of all locations with packages
      locations_with_at_least_one_package = Location.joins(:packages).where('packages_locations.quantity > 0')
      total = (locations_with_at_least_one_package.size / 2).to_i
      print "Creating #{total} stocktakes for 50% of all locations with packages"
      locations_with_at_least_one_package.take(total).each do |location|
        stocktake = FactoryBot.create(:stocktake, location: location, comment: "Demo stocktake", created_by: stock_administrator)
        location.packages.each do |package|
          quantity = PackagesInventory::Computer.package_quantity(package, location: location)
          FactoryBot.create(:stocktake_revision, quantity: quantity, package: package, stocktake: stocktake)
        end
        print '.'
      end
      puts
    end
  

  end

end
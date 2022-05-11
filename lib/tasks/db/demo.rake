require 'factory_bot'

#
# Make sure to run rake db:seed first
#    rake db:seed db:demo MULTIPLE=100
#
namespace :db do

  desc 'Create demo data. Specify multiple with MULTIPLE=42 rake db:demo. Run rake db:seed first.'
  task demo: :environment do
    abort("This job is not designed to be run in production mode. Aborting!") if Rails.env.production?
    puts "Generating demo data. MULTIPLE=#{count}"
    create_organisations
    create_contacts
    create_users
    create_offers
    create_orders
    puts
  end

  ###### METHODS ######

  def create_organisations
    print "Creating #{count} organisations"
    count.times do
      FactoryBot.create(:organisation)
      print '.'
    end
    puts
  end

  def create_contacts
    print "Creating #{count} contacts"
    count.times do
      FactoryBot.create(:contact)
      print '.'
    end
    puts
  end

  def create_offers
    print "Creating #{count * 7} offers"
    count.times do
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
    offer.update(delivered_by: FactoryBot.generate(:delivered_by))
  end

  def create_orders
    print "Creating #{count * 6} orders"
    count.times do
      FactoryBot.create(:appointment, :with_orders_packages, :with_state_submitted, :with_goodcity_requests, :with_order_transport_self, created_by: charity_user, processed_by: order_reviewer); print '.'
      FactoryBot.create(:appointment, :with_designated_orders_packages, :with_state_processing, :with_goodcity_requests, :with_order_transport_self, created_by: charity_user, processed_by: order_reviewer); print '.'
      FactoryBot.create(:appointment, :with_dispatched_orders_packages, :with_state_dispatching, :with_goodcity_requests, :with_order_transport_self, created_by: charity_user, processed_by: order_reviewer); print '.'

      FactoryBot.create(:online_order, :with_orders_packages, :with_state_submitted, :with_goodcity_requests, :with_order_transport_ggv, created_by: charity_user, processed_by: order_reviewer); print '.'
      FactoryBot.create(:online_order, :with_designated_orders_packages, :with_state_processing, :with_goodcity_requests, :with_order_transport_ggv, created_by: charity_user, processed_by: order_reviewer); print '.'
      FactoryBot.create(:online_order, :with_dispatched_orders_packages, :with_state_dispatching, :with_goodcity_requests, :with_order_transport_ggv, created_by: charity_user, processed_by: order_reviewer); print '.'
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

  def reviewer
    User.reviewers.sample || FactoryBot.create(:user, :reviewer)
  end

  def order_reviewer
    User.order_fulfilments.sample
  end

  def donor
    mobile = ["+85251111111", "+85251111112", "+85251111113", "+85251111114"].sample
    User.find_by_mobile(mobile)
  end

  def charity_user
    mobile = ["+85252222221", "+85252222222", "+85252222223", "+85252222224"].sample
    User.find_by_mobile(mobile)
  end

  def create_users
    print "Creating 48 users"
    donor_attributes = [
      { mobile: "+85251111111", first_name: "David", last_name: "Dara51" },
      { mobile: "+85251111112", first_name: "Daniel", last_name: "Dell52" },
      { mobile: "+85251111113", first_name: "Dakota", last_name: "Deryn53" },
      { mobile: "+85251111114", first_name: "Delia", last_name: "Devon54" },
      { mobile: "+85241111111", first_name: "Daemon", last_name: "Dara55" },
      { mobile: "+85241111112", first_name: "Daniela", last_name: "Dell56" },
      { mobile: "+85241111113", first_name: "Duke", last_name: "Deryn57" },
      { mobile: "+85241111114", first_name: "Dave", last_name: "Devon58" },
    ]
    donor_attributes.each {|attr| FactoryBot.create(:user, attr); print '.' }

    reviewer_attributes = [
      { mobile: "+85261111111", first_name: "Rachel", last_name: "Riley61" },
      { mobile: "+85261111112", first_name: "Robyn", last_name: "Raina62" },
      { mobile: "+85261111113", first_name: "Rafael", last_name: "Ras63" },
      { mobile: "+85261111114", first_name: "Raj", last_name: "Rakim64" },
      { mobile: "+85271111111", first_name: "Robert", last_name: "Dara65" },
      { mobile: "+85271111112", first_name: "Richard", last_name: "Dell66" },
      { mobile: "+85271111113", first_name: "Robil", last_name: "Deryn67" },
      { mobile: "+85271111114", first_name: "Richa", last_name: "Devon68" },
    ]
    reviewer_attributes.each {|attr| FactoryBot.create(:user, :reviewer, attr); print '.' }

    supervisor_attributes = [
      { mobile: "+85291111111", first_name: "Sarah", last_name: "Sahn91" },
      { mobile: "+85291111112", first_name: "Sally", last_name: "Salwa92" },
      { mobile: "+85291111113", first_name: "Saad", last_name: "Safa93" },
      { mobile: "+85291111114", first_name: "Scott", last_name: "Sandro94" },
      { mobile: "+85281111111", first_name: "Steve", last_name: "Sahn95" },
      { mobile: "+85281111112", first_name: "Smith", last_name: "Salwa96" },
      { mobile: "+85281111113", first_name: "Scarlett", last_name: "Safa97" },
      { mobile: "+85281111114", first_name: "Sky", last_name: "Sandro98" },
    ]
    supervisor_attributes.each {|attr| FactoryBot.create(:user, :supervisor, attr); print '.' }

    charity_attributes = [
      { mobile: "+85252222221", first_name: "Chris", last_name: "Chan521" },
      { mobile: "+85252222222", first_name: "Charlotte", last_name: "Cheung522" },
      { mobile: "+85252222223", first_name: "Charis", last_name: "Chen523" },
      { mobile: "+85252222224", first_name: "Carlos", last_name: "Chung524" },
      { mobile: "+85242222221", first_name: "Christian", last_name: "Chan525" },
      { mobile: "+85242222222", first_name: "Charlie", last_name: "Cheung526" },
      { mobile: "+85242222223", first_name: "Cathie", last_name: "Chen527" },
      { mobile: "+85242222224", first_name: "Cally", last_name: "Chung528" },
    ]
    charity_attributes.each {|attr| FactoryBot.create(:user, :charity, attr); print '.' }

    order_fulfiler_attributes = [
      { mobile: "+85262222221", first_name: "Olive", last_name: "Oakley621" },
      { mobile: "+85262222222", first_name: "Owen", last_name: "Ogilvy622" },
      { mobile: "+85262222223", first_name: "Oscar", last_name: "O'Riley623" },
      { mobile: "+85262222224", first_name: "Octavia", last_name: "O'Connor624" },
      { mobile: "+85272222221", first_name: "Oswald", last_name: "Oakley625" },
      { mobile: "+85272222222", first_name: "Ohio", last_name: "Ogilvy626" },
      { mobile: "+85272222223", first_name: "Omen", last_name: "O'Riley627" },
      { mobile: "+85272222224", first_name: "Owie", last_name: "O'Connor628" },
    ]
    order_fulfiler_attributes.each {|attr| FactoryBot.create(:user, :order_fulfilment, attr); print '.' }

    order_administrator_attributes = [
      { mobile: "+85263333331", first_name: "Fred", last_name: "Mercury631" },
      { mobile: "+85263333332", first_name: "Freddy", last_name: "Mercury632" },
      { mobile: "+85263333333", first_name: "Frederic", last_name: "Mercury633" },
      { mobile: "+85263333334", first_name: "Fredd", last_name: "Mercury634" },
      { mobile: "+85273333331", first_name: "Fredie", last_name: "Mercury635" },
      { mobile: "+85273333332", first_name: "Franky", last_name: "Mercury636" },
      { mobile: "+85273333333", first_name: "Frank", last_name: "Mercury637" },
      { mobile: "+85273333334", first_name: "Felicia", last_name: "Mercury638" },
    ]
    order_administrator_attributes.each {|attr| FactoryBot.create(:user, :order_administrator, attr); print '.' }
    puts
  end


  # Specify number of test cases to produce
  def count
    @count ||= begin
      multiple = ENV['MULTIPLE'].to_i # Note: nil.to_i = 0
      (multiple > 0) ? multiple : 10
    end
    @count
  end

end

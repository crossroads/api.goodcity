
require 'factory_girl'

namespace :demo do
  unless ENV['LIVE'] == "true"
    task load: :environment do

      ARGV.each { |a| task a.to_sym do ; end }

      #specify number of test cases to produce
      count_number= Integer(ARGV[1]) rescue 0 >0 ? ARGV[1].to_i : 10
      puts "This will generate #{count_number} record of Users, Offers, Packages, OrdersPackages, Orders, Contacts & Organisations"
      create_users count_number
      create_offers count_number
      create_package count_number
      create_orders_packages count_number
      create_orders count_number
      create_contacts count_number
      create_organizations count_number


    end

    def create_users count_number
      puts "User:\t\tCreating #{count_number} user accounts (donors, reviewers, supervisors) "
      #Create 10 user accounts (donors, reviewers, supervisors)
      count=count_number
      count.times do
        FactoryGirl.create(:user, :mobile_number)
      end

      count.times do
        FactoryGirl.create(:user, :reviewer, :mobile_number )
      end
      count.times do
        FactoryGirl.create(:user, :supervisor, :mobile_number )
      end
    end

    def create_offers count_number
      #Create 10 draft offers, 10 submitted, 10 under_review, 10 reviewed, 10 scheduled (with_transport), 10 closed(with_transport)
      puts "Offers:\t\tCreating #{count_number} draft offers, #{count_number}submitted, #{count_number} under_review, #{count_number} reviewed, #{count_number} scheduled (with_transport), #{count_number} closed(with_transport) "

      count=count_number
      count.times do
        offer=FactoryGirl.create(:offer, :with_items, :with_messages_body)
      end

      count.times do
        offer=FactoryGirl.create(:offer, :submitted, :with_items, :with_messages_body)
      end

      count.times do
        offer=FactoryGirl.create(:offer, :under_review, :with_items, :with_messages_body)
      end

      count.times do
        offer=FactoryGirl.create(:offer, :reviewed, :with_items, :with_messages_body)
      end

      count.times do
        offer=FactoryGirl.create(:offer, :scheduled, :with_transport, :with_items, :with_messages_body)
      end

      count.times do
        offer=FactoryGirl.create(:offer, :closed, :with_transport, :with_items, :with_messages_body)
      end
    end

    def create_package count_number
      #create Packages for Goodcity and Items for Stockit
      puts "Package:\t\tCreating #{count_number} Packages for Goodcity and Items for Stockit(with_item, with_set, with_set_item, received & stockit_package"
      count=count_number
      count_package=count/5
      count_package*2.times do
        FactoryGirl.create(:package, :with_item)
      end
      count_package.times do
        FactoryGirl.create(:package, :stockit_package)
      end
      count_package.times do
        FactoryGirl.create(:package, :with_set_item)
      end
      count_package.times do
        FactoryGirl.create(:package, :received)
      end
    end

    def create_single_order
        @organisation=FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)))
        @processor=FactoryGirl.create(:user, :reviewer, :mobile_number )
        FactoryGirl.create(:order, :with_created_by, processed_by: @processor, organisation: @organisation)
    end

    def create_orders_packages count_number
      puts "OrdersPackage:\t\tCreating #{count_number} OrdersPackages"
      #create OrdersPackages
      count=count_number
      count.times do
        @processor=FactoryGirl.create(:user, :reviewer, :mobile_number )
        @orders=create_single_order
        @package=FactoryGirl.create(:package, :with_item)
        @status=["draft", "submitted", "processing", "closed", "cancelled"].sample

        FactoryGirl.create( :orders_package,
                              package: @package,
                              order: @orders,
                              state: @status,
                              quantity: Random.rand(15),
                              reviewed_by: @processor
                            )
      end
    end

    def create_orders count_number
      puts "Orders:\t\tCreating #{count_number} Orders along with StockitLocalOrder"
      #create Orders along with StockitLocalOrder
      count=count_number
      count.times do
        create_single_order
      end
    end


    def create_contacts count_number
      puts "Contacts:\t\tCreating #{count_number} contacts"
      #create contact
      count=count_number
      count.times do
        FactoryGirl.create(:contact)
      end
    end

    def create_organizations count_number
      puts "Organisation:\t\tCreating #{count_number} organizations"
      #create organization
      count=count_number
      count.times do
        FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)))
      end
    end
  end
end

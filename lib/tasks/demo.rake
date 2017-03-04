require 'factory_girl'

# run rake db:seed first
# use 'rake demo:load n' to create n(only integers) record of each model
namespace :demo do
  unless ENV['LIVE'] == "true"
    task load: :environment do
      puts "This will generate #{count} record of Users, Offers, Packages, OrdersPackages, Orders, Contacts & Organisations"
      create_offers
      create_package
      create_orders_packages
      create_orders
      create_contacts
      create_organizations
    end

    def create_offers
      puts "Offers:\t\t\tCreating #{count} draft offers, #{count} submitted, #{count} under_review, #{count} reviewed, #{count} scheduled (with_transport), #{count} closed(with_transport)"
      count.times do
        FactoryGirl.create(:offer, :with_items, :with_messages, created_by: donor)
        FactoryGirl.create(:offer, :submitted, :with_items, :with_messages, created_by: donor)
        FactoryGirl.create(:offer, :under_review, :with_items, :with_messages, created_by: donor)
        FactoryGirl.create(:offer, :reviewed, :with_items, :with_messages, created_by: donor)
        FactoryGirl.create(:offer, :scheduled, :with_transport, :with_items, :with_messages, created_by: donor)
        FactoryGirl.create(:offer, :closed, :with_transport, :with_items, :with_messages, created_by: donor)
      end
    end

    def create_package
      # Create Packages for Goodcity and Items for Stockit
      puts "Package:\t\tCreating #{count} Packages for Goodcity and Items for Stockit(with_item, with_set, with_set_item, received & stockit_package"
      count_package = count/5
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
        @package = FactoryGirl.create(:package, :with_item)
        @orders_package = FactoryGirl.build(:orders_package,
                          package: @package,
                          order: @order,
                          quantity: @package.quantity,
                          updated_by: @updated_by
                        )
        if(@orders_package.state == "designated")
          @package.order_id = @order_id
        end
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

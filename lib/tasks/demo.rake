
require 'factory_girl'

namespace :demo do
  unless ENV['LIVE'] == "true"
    task load: :environment do

      #specify number of test cases to produce
      count=10
      @number="+8525"
      #Create 10 user accounts (donors, reviewers, supervisors)
      count.times do
        @number="+8525"+Random.rand(1000000).to_s.rjust(7,'0')
        FactoryGirl.create(:user, mobile: @number)
      end

      count.times do
        @number="+8525"+Random.rand(1000000).to_s.rjust(7,'0')
        FactoryGirl.create(:user, :reviewer, mobile: @number )
      end
      count.times do
        @number="+8525"+Random.rand(1000000).to_s.rjust(7,'0')
        FactoryGirl.create(:user, :supervisor, mobile: @number )
      end

      #Create 10 draft offers, 10 submitted, 10 under_review, 10 reviewed, 10 scheduled (with_transport), 10 closed(with_transport)

      #each Offer creates corresponding item so 60 items get created
      count=10
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

      #create Packages for Goodcity and Items for Stockit
      count=10
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

      #create OrdersPackages
      count=10
      count.times do
        @contact=FactoryGirl.create(:stockit_contact)
        @country= FactoryGirl.create( :country , name: ["China","USA", "India","Australia"].sample)
        @district= FactoryGirl.create(:district)
        @organisation=FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)), country: @country, district: @district)
        @stockit_organisation= FactoryGirl.create(:stockit_organisation)
        @status=["draft", "submitted", "processing", "closed", "cancelled"].sample
        @activity=FactoryGirl.create(:stockit_activity)
        @number="+8525"+Random.rand(1000000).to_s.rjust(7,'0')
        @creator= FactoryGirl.create(:user, mobile: @number)

        @number="+8525"+Random.rand(1000000).to_s.rjust(7,'0')
        @processor=FactoryGirl.create(:user, :reviewer, mobile: @number )
        @orders=FactoryGirl.create(:order,  stockit_contact: @contact,                          stockit_organisation: @stockit_organisation,
                                    description: FFaker::Lorem.sentence,
                                    stockit_activity: @activity,
                                    country: @country,
                                    created_by: @creator,
                                    processed_by: @processor,
                                    organisation: @organisation,
                                    state: @status
                           )

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

      #create Orders along with StockitLocalOrder
      count=10
      count.times do
        @contact=FactoryGirl.create(:stockit_contact)
        @country= FactoryGirl.create :country , name: ["China","USA", "India","Australia"].sample
        @district= FactoryGirl.create :district
        @organisation=FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)), country: @country, district: @district)
        @stockit_organisation= FactoryGirl.create(:stockit_organisation)
        @status=["draft", "submitted", "processing", "closed", "cancelled"].sample
        @activity=FactoryGirl.create(:stockit_activity)
        @number="+8525"+Random.rand(1000000).to_s.rjust(7,'0')
        @creator= FactoryGirl.create(:user, mobile: @number)

        @number="+8525"+Random.rand(1000000).to_s.rjust(7,'0')
        @processor=FactoryGirl.create(:user, :reviewer, mobile: @number )
        FactoryGirl.create(:order,  stockit_contact: @contact,                          stockit_organisation: @stockit_organisation,
                                    description: FFaker::Lorem.sentence,
                                    stockit_activity: @activity,
                                    country: @country,
                                    created_by: @creator,
                                    processed_by: @processor,
                                    organisation: @organisation,
                                    state: @status
                           )
      end

      #create contact
      count=10
      count.times do
        FactoryGirl.create(:contact)
      end

      #create organization
      count=10
      count.times do
        @country= FactoryGirl.create :country , name: ["China","USA", "India","Australia"].sample
        @district= FactoryGirl.create :district
        FactoryGirl.create(:organisation, organisation_type_id: OrganisationType.find_by_id(Random.rand(3)), country: @country, district: @district)
      end
    end
  end
end

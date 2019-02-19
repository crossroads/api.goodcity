require 'rails_helper'

context MessageSubscription do

  context "subscribe_users_to_message" do
  
    it "should subscribe the message sender"

    it "should subscribe the creator of the message related_object"

    it "should subscribe users who have sent previous messages"

    it "should subscribe admin users processing the offer"

    it "should not subscribe system users"

    it "should not subscribe donor if offer is cancelled"

    context "private messages" do
      
      it "should not subscribe donor"

      it "should subscribe all supervisors if none are already participating"

    end

  end

end
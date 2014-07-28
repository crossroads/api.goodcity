require 'rails_helper'

describe TwilioServices do

  describe "Twilio" do
      let!(:user) {create :user}
      it "should have user while initializing" do
        tw_user =TwilioServices.new(user)
        expect(tw_user.instance_values["user"]).to equal(user)
      end

      it "should throw an exception if there is no user" do
        expect {TwilioServices.new}.to raise_error(ArgumentError)
      end
    end
    describe "#sms_verification_pin"
      it "send sms to the given mobile" do
        # stub_request(:post, "https://AC6b8a8ca83ef5241cfba565c7cc3072f1:7264f04e543924113253ee98f2ef5d89@api.twilio.com/2010-04-01/Accounts/AC6b8a8ca83ef5241cfba565c7cc3072f1/SMS/Messages.json").
        # with(:body => {"Body"=>"Your pin is 530313 and will expire by 2014-07-28 13:13:49 UTC.", "From"=>"+18653126796", "To"=>"919930001948"},
        # :headers => {'Accept'=>'application/json', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'twilio-ruby/3.11.5 (true/x86_64-darwin12.0 2.1.1-p76)'}).
        # to_return(:status => 200, :body => "", :headers => {})
      end
    end
  end

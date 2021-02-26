require "rails_helper"

describe StripeService do

  let(:stripe_object) { StripeService.new(attributes) }

  let(:user) { create :user, :stripe_user }
  let(:new_user) { create :user }

  let(:stripe_setupintent_object) {
    {
      id: "seti_1IO3z18WYtC2zB",
      object: "setup_intent",
      customer: user.stripe_customer_id
    }
  }

  let(:attributes) {
    {
      source_type: 'transport_order',
      source_id: 1,
      authorize_amount: false,
    }
  }

  let(:stripe_payment_method_object) {
    {
      id: "seti_1IO3abJG1rVU42zB",
      payment_method: "pm_1IO3bbz1shC6ytgC",
      status: "requires_payment_method"
    }
  }

  let(:authorize_charge_response) {
    { id: "pi_1IO3bLJG1rVU4", status: "requires_capture" }
  }

  before { User.current_user = user }

  context "initialization" do
    it "user_id" do
      expect(stripe_object.user_id).to eql(user.id)
    end

    it "customer_id" do
      expect(stripe_object.customer_id).to eql(user.stripe_customer_id)
    end

    it "source_type" do
      expect(stripe_object.source_type).to eql(attributes[:source_type])
    end

    it "source_id" do
      expect(stripe_object.source_id).to eql(attributes[:source_id])
    end

    it "authorize_amount" do
      expect(stripe_object.authorize_amount).to eql(attributes[:authorize_amount])
    end
  end

  context "public_key" do
    it do
      expect(stripe_object.public_key).to eql(
         { publicKey: Rails.application.secrets.stripe[:publishable_key] }
      )
    end
  end

  context "stripe customer creation" do

    before { User.current_user = new_user }
    let(:stripe_customer_id) { "cus_J0KAOGkksjsbBT" }

    it "should hit stript endpoint to create new customer" do

      stub_request(:post, "https://api.stripe.com/v1/customers").
        with(
        body: {"email" => new_user.email, "name" => new_user.full_name, "phone" => new_user.mobile},
      ).to_return(status: 200, body: {id: stripe_customer_id}.to_json, headers: {})

      stripe_object = StripeService.new()

      expect(stripe_object.customer_id).to eq(stripe_customer_id)
      expect(new_user.reload.stripe_customer_id).to eq(stripe_customer_id)
    end
  end

  context "create_setup_intent" do
    it "should hit stripe to initiate stripe-payment process for customer" do

      stub_request(:post, "https://api.stripe.com/v1/setup_intents")
        .with(body: {"customer"=>"cus_IzVEJhwLTIZg1F"})
        .to_return(status: 200, body: stripe_setupintent_object.to_json, headers: {})

      expect(stripe_object.create_setup_intent.to_json).to eql(stripe_setupintent_object.to_json)
    end
  end

  context "save_payment_method" do
    it "add StripePayment record for customer payment-method details" do
      expect{
        stripe_object.save_payment_method(stripe_payment_method_object)
      }.to change(StripePayment, :count).by(1)

      payment = StripePayment.last
      expect(payment.setup_intent_id).to eq(stripe_payment_method_object[:id])
      expect(payment.payment_method_id).to eq(stripe_payment_method_object[:payment_method])
      expect(payment.status).to eq(stripe_payment_method_object[:status])
    end
  end

  context "authorize_amount_on_saved_card" do
    before { stripe_object.save_payment_method(stripe_payment_method_object) }

    it "should hit stripe to authorize charge manually" do

      stub_request(:post, "https://api.stripe.com/v1/payment_intents")
        .with(
          body: {
            amount: "20000",
            capture_method: "manual",
            confirm: "true",
            currency: "inr",
            customer: user.stripe_customer_id,
            off_session: "true",
            payment_method: stripe_payment_method_object[:payment_method]
        })
        .to_return(status: 200, body: authorize_charge_response.to_json, headers: {})

      stripe_object.authorize_amount_on_saved_card(20000, user.stripe_customer_id, stripe_payment_method_object[:payment_method])

      expect(StripePayment.last.payment_intent_id).to eq(authorize_charge_response[:id])
      expect(StripePayment.last.status).to eq(authorize_charge_response[:status])
    end
  end

  context "capture_payment" do
    it "should capture amount from authorized amount" do
      stub_request(:post, "https://api.stripe.com/v1/payment_intents/#{authorize_charge_response[:id]}/capture")
        .with( body: { amount_to_capture: "20000" }).to_return(status: 200, body: {}.to_json, headers: {})

      stripe_object.capture_payment(authorize_charge_response[:id], 20000)
    end
  end

end

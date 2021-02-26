## Steps for saving cards for future use:
## 1. Create or retrieve customer from associated user.
## 2. Create setup-intent for customer.
## 3. On client side: setup-intent-ID is passed, which is used to store card details and
##    returns payment-method details.
## 4. Update payment-method value in record. (created in step 2)
## 5. Authorize amount to above saved-card i.e. payment_method. Set capture_method as 'manual'
## 6. Capture payment

class StripeService

  attr_accessor :user_id, :source_type, :source_id, :customer_id, :amount, :payment,
                :authorize_amount

  def initialize(args={})
    @user_id = User.current_user.try(:id)
    @source_type = args[:source_type]
    @source_id = args[:source_id]
    @authorize_amount = args[:authorize_amount]

    Stripe.api_key = stripe_secret_key
    @customer_id = fetch_customer_id # STEP 1
  end

  # STEP 2
  def create_setup_intent
    Stripe::SetupIntent.create({
      customer: @customer_id
    })

    ## RESPONCE
    # #<Stripe::SetupIntent:0x3fd1c38065cc id=seti_1IOy9dJG1rVU4bz10kMAVLry> JSON: {
    #   "id": "seti_1IOyT3JG1rVU4bz1mBbHH6Yu",
    #   "object": "setup_intent",
    #   "application": null,
    #   "cancellation_reason": null,
    #   "client_secret": "seti_1IOyT3JG1rVU4bz1mBbHH6Yu_secret_J10Uje2R9PSUp74wN3S3TfwaDyCMMG8",
    #   "created": 1614314537,
    #   "customer": "cus_IzVEJkwLRIZg1F",
    #   "description": null,
    #   "last_setup_error": null,
    #   "latest_attempt": null,
    #   "livemode": false,
    #   "mandate": null,
    #   "metadata": {},
    #   "next_action": null,
    #   "on_behalf_of": null,
    #   "payment_method": null,
    #   "payment_method_options": {"card":{"request_three_d_secure":"automatic"}},
    #   "payment_method_types": [
    #     "card"
    #   ],
    #   "single_use_mandate": null,
    #   "status": "requires_payment_method",
    #   "usage": "off_session"
    # }
  end

  def public_key
    {
      'publicKey': stripe_publishable_key
    }
  end

  # STEP 4
  def save_payment_method(details)
    setup_stripe_payment(
      setup_intent_id: details[:id],
      status: details[:status],
      payment_method_id: details[:payment_method]
    )

    if @authorize_amount.to_s.downcase == 'true'
      authorize_amount_on_saved_card(amount_for_source, @customer_id, details[:payment_method])
    end
  end

  # STEP 5
  def authorize_amount_on_saved_card(amount, customer_id, payment_method_id)
    begin

      intent = Stripe::PaymentIntent.create({
        amount: amount,
        currency: "inr",
        customer: customer_id,
        payment_method: payment_method_id,
        off_session: true,
        confirm: true,
        capture_method: 'manual', # Ref: https://stripe.com/docs/payments/capture-later
      })

      ## RESPONSE:
      # #<Stripe::PaymentIntent:0x3fd680173608 id=pi_1IOyTuJG1rVU4bz1qiHYyCsO> JSON: {
      #   "id": "pi_1IOyTuJG1rVU4bz1qiHYyCsO",
      #   "object": "payment_intent",
      #   "amount": 30000,
      #   "amount_capturable": 30000,
      #   "amount_received": 0,
      #   "application": null,
      #   "application_fee_amount": null,
      #   "canceled_at": null,
      #   "cancellation_reason": null,
      #   "capture_method": "manual",
      #   "charges": {"object":"list","data":[{"id":"ch_1IOyTuJG1rVU4bz1t6dznTFj","object":"charge","amount":30000,"amount_captured":0,"amount_refunded":0,"application":null,"application_fee":null,"application_fee_amount":null,"balance_transaction":null,"billing_details":{"address":{"city":null,"country":null,"line1":null,"line2":null,"postal_code":"42424","state":null},"email":"swati@kiprosh.com","name":null,"phone":null},"calculated_statement_descriptor":"Stripe","captured":false,"created":1614315794,"currency":"inr","customer":"cus_IzVEJkwLRIZg1F","description":null,"destination":null,"dispute":null,"disputed":false,"failure_code":null,"failure_message":null,"fraud_details":{},"invoice":null,"livemode":false,"metadata":{},"on_behalf_of":null,"order":null,"outcome":{"network_status":"approved_by_network","reason":null,"risk_level":"normal","risk_score":43,"seller_message":"Payment complete.","type":"authorized"},"paid":true,"payment_intent":"pi_1IOyTuJG1rVU4bz1qiHYyCsO","payment_method":"pm_1IOyTrJG1rVU4bz1wYJv9s5N","payment_method_details":{"card":{"brand":"visa","checks":{"address_line1_check":null,"address_postal_code_check":"pass","cvc_check":"pass"},"country":"US","exp_month":4,"exp_year":2024,"fingerprint":"VTCnHArgdpMTv44P","funding":"credit","installments":null,"last4":"4242","network":"visa","three_d_secure":null,"wallet":null},"type":"card"},"receipt_email":null,"receipt_number":null,"receipt_url":"https://pay.stripe.com/receipts/acct_1IBXaDJG1rVU4bz1/ch_1IOyTuJG1rVU4bz1t6dznTFj/rcpt_J10Uwnh11pAfJsEc8fnTHmGeBHcq3Iv","refunded":false,"refunds":{"object":"list","data":[],"has_more":false,"total_count":0,"url":"/v1/charges/ch_1IOyTuJG1rVU4bz1t6dznTFj/refunds"},"review":null,"shipping":null,"source":null,"source_transfer":null,"statement_descriptor":null,"statement_descriptor_suffix":null,"status":"succeeded","transfer_data":null,"transfer_group":null}],"has_more":false,"total_count":1,"url":"/v1/charges?payment_intent=pi_1IOyTuJG1rVU4bz1qiHYyCsO"},
      #   "client_secret": "pi_1IOyTuJG1rVU4bz1qiHYyCsO_secret_UVumzun2tSD79h3haVp7wuUEh",
      #   "confirmation_method": "automatic",
      #   "created": 1614315794,
      #   "currency": "inr",
      #   "customer": "cus_IzVEJkwLRIZg1F",
      #   "description": null,
      #   "invoice": null,
      #   "last_payment_error": null,
      #   "livemode": false,
      #   "metadata": {},
      #   "next_action": null,
      #   "on_behalf_of": null,
      #   "payment_method": "pm_1IOyTrJG1rVU4bz1wYJv9s5N",
      #   "payment_method_options": {"card":{"installments":null,"network":null,"request_three_d_secure":"automatic"}},
      #   "payment_method_types": [
      #     "card"
      #   ],
      #   "receipt_email": null,
      #   "review": null,
      #   "setup_future_usage": null,
      #   "shipping": null,
      #   "source": null,
      #   "statement_descriptor": null,
      #   "statement_descriptor_suffix": null,
      #   "status": "requires_capture",
      #   "transfer_data": null,
      #   "transfer_group": null
      # }

      # Update payment-intent details for customer's service.
      @payment.update({payment_intent_id: intent["id"], status: intent["status"]})

    rescue Stripe::CardError => e
      # TODO
      # Error code will be authentication_required if authentication is needed
      puts "Error is: #{e.error.code}"
      payment_intent_id = e.error.payment_intent.id
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
      puts payment_intent.id
    end
  end

  # STEP 6
  # Capture payment when specific service(transport-order) is completed.
  def capture_payment(payment_intent_id, amount)
    intent = Stripe::PaymentIntent.capture(
      payment_intent_id,
      {
        amount_to_capture: amount,
      }
    )

    ## RESPONSE
    ## <Stripe::PaymentIntent:0x3fd1c63fc1a4 id=pi_1IOyTuJG1rVU4bz1qiHYyCsO> JSON: {
    #   "id": "pi_1IOyTuJG1rVU4bz1qiHYyCsO",
    #   "object": "payment_intent",
    #   "amount": 30000,
    #   "amount_capturable": 0,
    #   "amount_received": 20000,
    #   "application": null,
    #   "application_fee_amount": null,
    #   "canceled_at": null,
    #   "cancellation_reason": null,
    #   "capture_method": "manual",
    #   "charges": {"object":"list","data":[{"id":"ch_1IOyTuJG1rVU4bz1t6dznTFj","object":"charge","amount":30000,"amount_captured":20000,"amount_refunded":10000,"application":null,"application_fee":null,"application_fee_amount":null,"balance_transaction":"txn_1IOyZMJG1rVU4bz10NuRnEhQ","billing_details":{"address":{"city":null,"country":null,"line1":null,"line2":null,"postal_code":"42424","state":null},"email":"swati@kiprosh.com","name":null,"phone":null},"calculated_statement_descriptor":"Stripe","captured":true,"created":1614315794,"currency":"inr","customer":"cus_IzVEJkwLRIZg1F","description":null,"destination":null,"dispute":null,"disputed":false,"failure_code":null,"failure_message":null,"fraud_details":{},"invoice":null,"livemode":false,"metadata":{},"on_behalf_of":null,"order":null,"outcome":{"network_status":"approved_by_network","reason":null,"risk_level":"normal","risk_score":43,"seller_message":"Payment complete.","type":"authorized"},"paid":true,"payment_intent":"pi_1IOyTuJG1rVU4bz1qiHYyCsO","payment_method":"pm_1IOyTrJG1rVU4bz1wYJv9s5N","payment_method_details":{"card":{"brand":"visa","checks":{"address_line1_check":null,"address_postal_code_check":"pass","cvc_check":"pass"},"country":"US","exp_month":4,"exp_year":2024,"fingerprint":"VTCnHArgdpMTv44P","funding":"credit","installments":null,"last4":"4242","network":"visa","three_d_secure":null,"wallet":null},"type":"card"},"receipt_email":null,"receipt_number":null,"receipt_url":"https://pay.stripe.com/receipts/acct_1IBXaDJG1rVU4bz1/ch_1IOyTuJG1rVU4bz1t6dznTFj/rcpt_J10Uwnh11pAfJsEc8fnTHmGeBHcq3Iv","refunded":false,"refunds":{"object":"list","data":[{"id":"re_1IOyZMJG1rVU4bz1xhvil8nK","object":"refund","amount":10000,"balance_transaction":"txn_1IOyZMJG1rVU4bz1oRiPReWp","charge":"ch_1IOyTuJG1rVU4bz1t6dznTFj","created":1614316132,"currency":"inr","metadata":{},"payment_intent":"pi_1IOyTuJG1rVU4bz1qiHYyCsO","reason":null,"receipt_number":null,"source_transfer_reversal":null,"status":"succeeded","transfer_reversal":null}],"has_more":false,"total_count":1,"url":"/v1/charges/ch_1IOyTuJG1rVU4bz1t6dznTFj/refunds"},"review":null,"shipping":null,"source":null,"source_transfer":null,"statement_descriptor":null,"statement_descriptor_suffix":null,"status":"succeeded","transfer_data":null,"transfer_group":null}],"has_more":false,"total_count":1,"url":"/v1/charges?payment_intent=pi_1IOyTuJG1rVU4bz1qiHYyCsO"},
    #   "client_secret": "pi_1IOyTuJG1rVU4bz1qiHYyCsO_secret_UVumzun2tSD79h3haVp7wuUEh",
    #   "confirmation_method": "automatic",
    #   "created": 1614315794,
    #   "currency": "inr",
    #   "customer": "cus_IzVEJkwLRIZg1F",
    #   "description": null,
    #   "invoice": null,
    #   "last_payment_error": null,
    #   "livemode": false,
    #   "metadata": {},
    #   "next_action": null,
    #   "on_behalf_of": null,
    #   "payment_method": "pm_1IOyTrJG1rVU4bz1wYJv9s5N",
    #   "payment_method_options": {"card":{"installments":null,"network":null,"request_three_d_secure":"automatic"}},
    #   "payment_method_types": [
    #     "card"
    #   ],
    #   "receipt_email": null,
    #   "review": null,
    #   "setup_future_usage": null,
    #   "shipping": null,
    #   "source": null,
    #   "statement_descriptor": null,
    #   "statement_descriptor_suffix": null,
    #   "status": "succeeded",
    #   "transfer_data": null,
    #   "transfer_group": null
    # }

  end

  private

  def stripe_publishable_key
    Rails.application.secrets.stripe[:publishable_key]
  end

  def stripe_secret_key
    Rails.application.secrets.stripe[:secret_key]
  end

  def fetch_customer_id
    user = User.find_by(id: @user_id)
    user&.stripe_customer_id || create_customer(user)
  end

  def create_customer(user)
    customer = Stripe::Customer.create({
      email: user&.email,
      name: user&.full_name,
      phone: user&.mobile,
    })

    user.update_column(:stripe_customer_id, customer.id)
    customer.id
  end

  def setup_stripe_payment(details)
    @payment = StripePayment.create(
      setup_intent_id: details[:setup_intent_id],
      payment_method_id: details[:payment_method_id],
      status: details[:status],
      user_id: @user_id,
      amount: @amount,
      source_id: @source_id,
      source_type: @source_type
    )
  end

  # TODO:
  # Fetch amount from the source for which amount has to be deducted.
  def amount_for_source
    if @source_id && @source_type
      # @amount = @payment&.source&.amount
      @amount = 30000
    end

    @amount
  end

end

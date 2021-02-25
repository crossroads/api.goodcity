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

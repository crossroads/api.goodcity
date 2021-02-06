## Steps for saving cards for future use:
## 1. Create or retrieve custome from associated user.
## 2. Create setup-intent for customer. (Save setup-intent-ID and customer-ID for future use)
## 3. On client side: setup-intent-ID is passed, which is used to store card details and
##    returns payment-method details.
## 4. Update payment-method value in record. (created in step 2)

class StripeService

  def initialize
    Stripe.api_key = stripe_secret_key
  end

  def create_customer(user)
    customer = Stripe::Customer.create({
      email: user&.email,
      name: user&.full_name,
      phone: user&.mobile,
    })

    ## TODO:
    ## Save customer-id as stripe_customer_id for User

    customer
  end

  def fetch_customer(user_id=nil)
    user = user_id ? User.find_by(id: user_id) : User.current_user
    customer_response = nil

    ## TODO:
    ## Add column stripe_customer_id in users.

    # if user&.stripe_customer_id
    #   begin
    #     customer_response = Stripe::Customer.retrieve(user.stripe_customer_id)
    #   rescue Stripe::InvalidRequestError => e
    #     create_customer(user)
    #   end
    # else
    #   create_customer(user)
    # end

    customer_response = Stripe::Customer.retrieve("cus_IqFB5lMIYw6i8a")
  end

  def create_setup_intent(user_id=nil)
    customer = fetch_customer(user_id)

    setup_intent_response = Stripe::SetupIntent.create({
      customer: customer['id']
    })

    ## TODO:
    ## Add new record having setup-intent-id and customer-id in stripe-payments table

    setup_intent_response
  end

  ## Reference: https :/ / stripe.com / docs / payments / capture - later
  # def create_payment_intent(amount, currency, offer_id)
  #   intent = Stripe::PaymentIntent.create({
  #     amount: amount,
  #     currency: currency,
  #     payment_method_types: ['card'],
  #     statement_descriptor: "GOGOX Booking Charge for offer ##{offer_id}",
  #     setup_future_usage: 'off_session',
  #     capture_method: 'manual',
  #     metadata: {
  #       integration_check: "accept_a_payment",
  #       offer_id: offer_id,
  #     },
  #   })
  # end

  def public_key
    {
      'publicKey': stripe_publishable_key
    }
  end

  private

  def stripe_publishable_key
    Rails.application.secrets.stripe[:publishable_key]
  end

  def stripe_secret_key
    Rails.application.secrets.stripe[:secret_key]
  end

end

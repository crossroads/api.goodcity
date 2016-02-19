class BraintreeService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def client_token
    Braintree::ClientToken.generate(customer_id: user.braintree_customer_id)
  end

  def create_transaction(amount, nonce_token)
    result = if user.has_payment_info?
      new_transaction(amount, nonce_token)
    else
      new_transaction_with_customer(amount, nonce_token)
    end

    if result.success?
      save_customer_id(result.transaction)
      add_transaction(result.transaction)
    end

    result.success?
  end

  private

  def save_customer_id(transaction)
    user.update(braintree_customer_id: transaction.customer_details.id) unless user.has_payment_info?
  end

  def add_transaction(transaction)
    BraintreeTransaction.create(
      transaction_id: transaction.id,
      customer_id: transaction.customer_details.id,
      amount: transaction.amount,
      status: transaction.status
    )
  end

  def new_transaction_with_customer(amount, nonce_token)
    options = {
      customer: {
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.mobile
      },
      options: {
        store_in_vault: true
      }
    }
    new_transaction(amount, nonce_token, options)
  end

  def new_transaction(amount, nonce_token, options = {})
    Braintree::Transaction.sale(
      { amount: amount,
        payment_method_nonce: nonce_token
      }.merge(options)
    )
  end

end

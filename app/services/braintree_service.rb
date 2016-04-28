class BraintreeService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def client_token
    token_id = has_transactions_details? ? user.id : nil
    Braintree::ClientToken.generate(customer_id: token_id)
  end

  def create_transaction(amount, nonce_token)
    result = if has_transactions_details?
      new_transaction(amount, nonce_token)
    else
      new_transaction_with_customer(amount, nonce_token)
    end

    add_transaction(result.transaction) if result.success?

    result
  end

  private

  def has_transactions_details?
    user.braintree_transactions.present?
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
        id: user.id,
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
        payment_method_nonce: nonce_token,
        options: {
          submit_for_settlement: true
        }
      }.deep_merge(options)
    )
  end

end

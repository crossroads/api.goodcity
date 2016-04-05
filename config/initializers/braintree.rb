braintree_creds = Rails.application.secrets.braintree

Braintree::Configuration.environment = (braintree_creds["environment"] || "sandbox").to_sym
Braintree::Configuration.merchant_id = braintree_creds["merchant_id"]
Braintree::Configuration.public_key = braintree_creds["public_key"]
Braintree::Configuration.private_key = braintree_creds["private_key"]

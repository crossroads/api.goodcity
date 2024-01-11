# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :auth, :flat, :building, :street, :identity_number, :first_name, :last_name, :phone, :serial_num, :mobile, :name,
  :driver_license, :description, :value, :body, :staff_note, :note, :preferred_contact_number, :comment, :username,
  :client_name, :hkid, :reference_number, :email, :object, :object_changes, :Called, :To, :From, :Caller]

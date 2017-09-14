# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_payment_voucher_session',
  :secret      => '47af2d7e59909b3ce02956ae4a20396a16f8c5dabaa811b008896f48dcf46b9f521488a534d724955c556ae9082aebda45a6d43a6af3f570648e6a40a8418440'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

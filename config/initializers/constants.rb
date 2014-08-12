ISSUER = "GoodCityHK"
HMAC_SHA_ALGO = "HS256"   # For cryptography HMAC using SHA-256 hash algorithm -> jwt
OTP_TOKEN_VALIDITY = 1800 # Valid for 30  minutes
JWT_SECRET_KEY = ENV['JWT_SECRET_KEY']


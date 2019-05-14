TITLE_OPTIONS = %w(Mr Mrs Miss Ms)
SUBSCRIPTION_REMINDER_TIME_DELTA = 4.hours
NEXT_AVAILABLE_DAYS_COUNT = 40
START_DAYS_COUNT = 0
CROSSROADS_TRUCK_COST = 600
DEFAULT_SEARCH_COUNT = 25
DONOR_APP = "app".freeze
ADMIN_APP = "admin".freeze
STOCK_APP = "stock".freeze
BROWSE_APP = "browse".freeze
STOCKIT_APP = "stockit".freeze
SKIP_AUTH_APP_NAMES = [DONOR_APP, BROWSE_APP].freeze
APP_NAMES = [DONOR_APP, ADMIN_APP, STOCK_APP, BROWSE_APP, STOCKIT_APP].freeze
STAFF_APPS = [ADMIN_APP, STOCK_APP, STOCKIT_APP].freeze
STAFF_APPS_FOR_LOGIN = [ADMIN_APP, STOCKIT_APP].freeze
ACTIVE_ORDERS = ["submitted", "processing", "awaiting_dispatch", "dispatching"].freeze
GGV_POLL_JOB_WAIT_TIME = 60.seconds
GGV_POLL_JOB_WAIT_TIME_FOR_ONLINE_DONOR = 30.seconds
SYSTEM_USER_MOBILE = "+85264522773"
GOODCITY_NUMBER = "+85222729348"
TWILIO_QUEUE_WAIT_TIME = 30
STOCKIT_PREFIX = "X"
APP_NAME_AND_LOGIN_PERMISSION_MAPPING = {
  ADMIN_APP => 'can_login_to_admin',
  STOCK_APP => 'can_login_to_stock',
  BROWSE_APP => 'can_login_to_browse'
}

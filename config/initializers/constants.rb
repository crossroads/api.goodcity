NEXT_AVAILABLE_DAYS_COUNT = 40
START_DAYS_COUNT = 0
CROSSROADS_TRUCK_COST = 600
DONOR_APP = "app.goodcity"
ADMIN_APP = "admin.goodcity"
STOCK_APP = "stock.goodcity"
BROWSE_APP = "browse.goodcity"
STOCKIT_APP = "stockit"
STAFF_APPS = [ADMIN_APP, STOCK_APP, STOCKIT_APP]
STAFF_APPS_FOR_LOGIN = [ADMIN_APP, STOCKIT_APP]
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
FORCE_APP_INSTALL = {
  "app.goodcity": { minor_version: "0.16", should_push: true},
  "admin.goodcity": { minor_version: "0.14.1", should_push: true},
  "stock.goodcity": { minor_version: "0.4", should_push: true},
  "browse.goodcity": { minor_version: "0.7", should_push: true}
}
## TWILIO OUTBOUND SETUP:

#### Setup TwiML Application
  [Link:](https://www.twilio.com/user/account/apps) (Currently we have 3 apps for development, staging and production environment.)
#### TwiML Application has following things:
#####Sid:
- This value is used as `ENV['TWILIO_CALL_APP_SID']` in api.
- Using `ENV['TWILIO_ACCOUNT_SID']`, `ENV['TWILIO_AUTH_TOKEN']` and `ENV['TWILIO_CALL_APP_SID']` we create capability token, which is sent to Admin Browser which allows Admin to make a call from browser.

#####Request URL:
  - Retrieve and execute the TwiML at this URL via the selected HTTP method when this application receives a phone call.
  - Example: https://api-staging.goodcity.hk/api/v1/twilio_outbound/connect_call

#####Status Callback URL:
  - Make a request to this URL when a call to this application is completed.
  - Example: https://api-staging.goodcity.hk/api/v1/twilio_outbound/call_status

## TWILIO INBOUND SETUP:

#### Setup Phone Number for Voice-Call:
* Currently we are using following numbers [Link:](https://www.twilio.com/user/account/phone-numbers/incoming)
 - Development: +852 5808 7803
 - Staging:     +852 5808 4822
* This is used as `ENV['TWILIO_VOICE_NUMBER']` in api.

#####Request URL:
  - Retrieve and execute the TwiML at this URL via the selected HTTP method when this application receives a phone call.
  - Example: https://api-staging.goodcity.hk/api/v1/twilio_inbound/voice

#####Fallback URL:
  - Retrieve and execute the TwiML at this URL when the voice request URL can't be reached or there is runtime exception or invalid response.
  - Example: https://api-staging.goodcity.hk/api/v1/twilio_inbound/call_fallback

#####Status Callback URL:
  - Make a request to this URL when a call to this phone number is completed.
  - Example: https://api-staging.goodcity.hk/api/v1/twilio_inbound/call_complete

## TWILIO TASKROUTER SETUP:

#### Setup Workspace
  * Link: https://www.twilio.com/user/account/taskrouter/workspaces
  * Currently we have different workspaces for different environments. (Workspace can be created with some friendly name)
  * The workspace sid value is used as `ENV['TWILIO_WORKSPACE_SID']` in api.

#### Setup TaskQueue
  * Link: `https://www.twilio.com/user/account/taskrouter/workspaces/#{ENV['TWILIO_WORKSPACE_SID']}/taskqueues`
  * Currently we have created one taskqueue for workspace. 
(TaskQueue can be created with `Friendly name`, `Reservation Activity` as `offline`, `Assignment Activity` as `offline` and `Target Workers` as sql expression for ex:  `languages HAS "en"`)

#### Setup Workflow
  * link: `https://www.twilio.com/user/account/taskrouter/workspaces/#{ENV['TWILIO_WORKSPACE_SID']}/workflows`
  * Currently we have created one workflow for workspace. 
(Workflow can be created with `Friendly name`, `Assignment Callback Url` and `Timeout` values)

  * **Assignment Callback URL** is the HTTP endpoint that TaskRouter uses to notify your application of a reservation. See the assignment instructions documentation for more information.
    - Example: https://api-staging.goodcity.hk/api/v1/twilio_inbound/assignment
  
  * For Routing Configuration of workflow, we can add a filter, example: we have created filter with expression `selected_language == "en"`

#### Setup Worker
  * Link: `https://www.twilio.com/user/account/taskrouter/workspaces/#{ENV['TWILIO_WORKSPACE_SID']}/workers`
  * We have created one worker for given workspace. (Worker can be created with `Friendly Name` and `Attributes` for ex: `{"languages":["en"],"user_id":""}`)
  
#### Important Things:
* Worker has following activities: 
  - offline
  - idle
  - busy
  - reserved
* Worker will be assigned to Task, only if worker is in **Idle** activity.
* As the `ENV['TWILIO_VOICE_NUMBER']` receives call, it will request TwiML response at `https://api-staging.goodcity.hk/api/v1/twilio/voice` and will create a task for that received call.
* We will keep Worker in **Offline** activity always, as Admin accepts call-notification, we will mark worker as **Idle**
* As our Workflow found and **Idle Worker**, it will make a request at **Assignment Callback URL**. This will return json response with `{instruction: 'Dequeue', To: <Admin>, From: <Twilio-Number>, post_activity_sid: <offline_activity_sid>}`
* Now it will redirect incoming call to Admin's Mobile and once the call is over, it will send worker to **Offline** state.

#### In Development:
* Use ngrok, to provide access to Twilio to your local application
* To test outbound call: update `Request URL` and `Status Callback URL` for TwiML Development App.
* To test inbound call: update `Request URL`, `Fallback URL` and `Status Callback URL` of the Twilio Phone Number used in Development.
* For Taskrouter: update `Assignment Callback URL` of workflow

#### Reference Links:
* https://www.twilio.com/taskrouter
* https://www.twilio.com/blog/2014/02/twilio-on-rails-integrating-twilio-with-your-rails-4-app.html
* http://blog.bigbinary.com/2014/09/29/twilio-rails-calling-from-browser-to-a-phone.html

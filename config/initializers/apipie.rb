Apipie.configure do |config|
  config.app_name                = "GoodCity API"
  config.copyright               = "&copy; Crossroads Foundation Limited"
  config.api_base_url            = "/api"
  config.doc_base_url            = "/api/docs"
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/v1/*.rb"
  config.default_version         = "v1"
  config.app_info                = "
  == Getting Started

  All links below should be prefixed with http://api.goodcity.hk

  == Authentication

  == Language

  Some taxonomy lists such as ItemTypes, Districts and Territories have Traditional Chinese 中文 translations.
  When sending an API request, include the following header to set the language. This will return responses
  that include applicable translations. If no language header is set or the language requested is not available,
  the API will default to English.

      Accept-Language: zh-tw

  === Example responses:

  *English*

    {
      territory: {
        id: 1,
        name: \"New Territories\"
      }
    }

  *Traditional Chinese*

    {
      territory: {
        id: 1,
        name: \"新界\"
      }
    }


  == Permissions

  The API will only provide access to objects the user has permission to see.
  For example: when a donor lists all offers, only offers they have created are returned.
  When a 'Reviewer' views all offers, they will see everything.

  == Paginiation

  Currently no pagination is implemented.

  "
  #~ config.authenticate = Proc.new do
     #~ authenticate_or_request_with_http_basic do |username, password|
       #~ username == "test" && password == "supersecretpassword"
    #~ end
  #~ end
end

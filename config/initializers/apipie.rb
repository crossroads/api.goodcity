# encoding: utf-8
Apipie.configure do |config|
  config.app_name                = "GoodCity API"
  config.copyright               = "&copy; Crossroads Foundation Limited"
  config.api_base_url            = "/api"
  config.doc_base_url            = "/api/docs"
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/v1/*.rb"
  config.default_version         = "v1"
  #config.use_cache = Rails.env.production? # use with rake apipie:cache to use cached documents in production
  #~ config.authenticate = Proc.new do
     #~ authenticate_or_request_with_http_basic do |username, password|
       #~ username == "test" && password == "supersecretpassword"
    #~ end
  #~ end
  config.app_info                = <<-EOS
  == Getting Started

  All links below should be prefixed with http://api.goodcity.hk

  == Architecture / Diagrams

  * {API Controllers and Actions}[/doc/controllers_complete.svg]
  * {Database Models (overview of relationships)}[/doc/models_brief.svg]
  * {Database Models (full schema)}[/doc/models_complete.svg]

  == Authentication

  See {/api/docs/v1/authentication.html}[/api/docs/v1/authentication.html]

  == Language

  Some taxonomy lists such as ItemTypes, Districts and Territories have Traditional Chinese 中文 translations.
  When sending an API request, include the following header to set the language. This will return translated
  data (where applicable). If no language header is set or the language requested is not available,
  the API will default to English.

  The Accept-Language headers allows the following options:

      Accept-Language: en
      Accept-Language: zh-tw

  ===English

    {
      territory: {
        id: 1,
        name: \"New Territories\"
      }
    }

  ===Traditional Chinese

    {
      territory: {
        id: 1,
        name: \"新界\"
      }
    }


  == Permissions

  The API will only provide access to objects the authenticated user has permission to see.
  For example: when a donor lists all offers, only offers they have created are returned.
  When a Reviewer views all offers, they will see everything.

  == Validation Error Handling

  Validation errors return status <code>422 Unprocessable Entity</code> and will generally include a json errors attributes hash. For example:

    {
      errors:
        {
          mobile: "is invalid"
        }
    }

  == Server responses (non 2XX)

  If you send a request to the server without the correct parameters, the response will be <code>400 Bad Request</code>

    {
      error: "Bad Request"
    }

  <code>401 Unauthorized</code> errors return the following format:

    {
      error: "Invalid token"
    }

  If there is a <code>500 Server Error</code>, it will be returned in the following format:

    {
      error: "Internal Server Error"
    }

  == Serialization

  All responses are serialized in JSON format. Objects are serialized using {ActiveModelSerializer}[https://github.com/rails-api/active_model_serializers].

  Partial example:

    {
      "offer" : {
        "id" : 1731,
        "language" : "en",
        "state" : "draft",
        "origin" : "web",
        "stairs" : false,
        "parking" : false,
        "estimated_size" : "4"
      }
    }

  Please refer to a specific controller for more detailed examples.

  == Side-loading

  Objects that contain related data may also include those relationships to reduce the number of API requests required.

  In the following example, an API call has been made to <code>/api/v1/territories/306</code>.
  The response payload includes both the territory attributes and the related districts.

    {
      "districts" : [
        {
          "id" : 118,
          "name" : "Shek Kong",
          "territory_id" : 306
        },
        {
          "id" : 119,
          "name" : "Tsz Wan Shan",
          "territory_id" : 306
        },
      ],
      "territory" : {
        "id" : 306,
        "name" : "New Territories",
        "district_ids" : [
          118,
          119,
        ]
      }
    }

  == Paginiation

  Currently no pagination is implemented.

  EOS

end

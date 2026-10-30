# Ordinals for zh-tw (API-63). ActiveSupport defines `number.nth` only for :en, so `11.ordinalize` under zh-tw
# rendered "Translation missing: zh-tw.number.nth.ordinalized" inside every delivery push and schedule label.
# Chinese has no "th": the day is just its number.
{
  "zh-tw": {
    number: {
      nth: {
        ordinals: ->(_key, _options) { "" },
        ordinalized: ->(_key, options) { options[:number].to_s }
      }
    }
  }
}

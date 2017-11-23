module RollbarSpecification
  extend ActiveSupport::Concern

  included do
    after_validation :report_validation_errors_to_rollbar, if: :request_from_stockit?
  end

  def request_from_stockit?
    GoodcitySync.request_from_stockit
  end
end

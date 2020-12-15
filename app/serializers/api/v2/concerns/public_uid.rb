module Api::V2::Concerns
  module PublicUID
    extend ActiveSupport::Concern

    included do
      attribute :public_uid,
        if: Proc.new { |_, params = {}|
          params[:include_public_uid] == true
        } do |object|
          Shareable.public_uid_of(object)
        end
      end
  end
end

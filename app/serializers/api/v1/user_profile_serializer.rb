module Api::V1
  class UserProfileSerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :mobile, :donation_amount,
      :donation_date

    has_one :address, serializer: AddressSerializer
    has_one :image, serializer: ImageSerializer
    has_one :permission, serializer: PermissionSerializer

    def mobile
      object.try(:mobile) && object.mobile.slice(4..-1)
    end

    def recent_donation
      object.braintree_transactions.where(is_success: true).
      order("id desc").first
    end

    def donation_date
      recent_donation.try(:created_at)
    end

    def donation_amount
      recent_donation.try(:amount)
    end
  end
end

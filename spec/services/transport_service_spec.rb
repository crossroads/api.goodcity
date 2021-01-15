require "rails_helper"

describe TransportService do

  let(:scheduled_at)   { "Wed, 30 Dec 2020 15:10:08.000000000 +0800" }
  let(:district)     { (create :district) }
  let(:vehicle)      { "van" }
  let(:user)         { (create :user) }
  let!(:provider)    { (create :transport_provider, name: "GOGOX") }
  let(:gogox_booking_id) { "2f859363-5c43-4fe2-9b91-6c6c43d610d2" }

  let!(:transport_order) {
    create :transport_order, transport_provider: provider,
      order_uuid: gogox_booking_id
  }

  let(:gogox_booking_response) {
    {
      "uuid" => "2f859363-5c43-4fe2-9b91-6c6c43d610d2",
      "status" => "pending",
      "vehicle_type" => "van",
      "payment_method" => "prepaid_wallet",
      "price" => {"amount" => 15000, "currency" => "HKD"},
      "price_breakdown" => [{"key" => "fee", "amount" => 15000}],
      "pickup" => { "schedule_at" => 7866788998 }
    }
  }

  let(:attributes) {
    {
      provider: "Gogox",
      district_id: district.id,
      vehicle_type: vehicle,
      scheduled_at: scheduled_at,
      user_id: user.id,
      booking_id: gogox_booking_id
    }
  }

  let(:transport) { TransportService.new(attributes) }

  context "initialization" do
    it "params" do
      expect(transport.params).to eql(attributes)
    end
    it "district_id" do
      expect(transport.district_id).to eql(district.id)
    end
    it "user" do
      expect(transport.user).to eql(user)
    end
    it "provider" do
      expect(transport.provider).to eql(Gogox)
    end
  end

  context "quotation" do
    let(:response) {
      {
        "vehicle_type" => "van",
        "estimated_price" => {"amount" => 15000, "currency" => "HKD"},
        "estimated_price_breakdown" => [{"key" => "fee", "amount" => 15000}]
      }
    }

    let(:quotation_attributes) {
      {
        'vehicle_type': vehicle,
        "scheduled_at": scheduled_at,
        "pickup_location": [22.5029632, 114.1277213],
        "destination_location": [56.8766894, 120.9891416]
      }
    }

    it 'should trigger Gogox Service' do
      mock_object = instance_double(Gogox, quotation: response)
      allow(Gogox).to receive(:new).with(quotation_attributes)
          .and_return(mock_object)
      expect(transport.quotation).to eq(response)
    end
  end

  context "book" do
    let(:transport) {
      TransportService.new({
        provider: "Gogox",
        district_id: district.id,
        vehicle_type: vehicle,
        scheduled_at: scheduled_at,
        user_id: user.id,
        pickup_street_address: 'Road',
        pickup_contact_name: 'Swati',
        pickup_contact_phone: '+85251111118'
      })
    }

    let(:order_attributes) {
      {
        destination_contact_name: "Swati",
        destination_contact_phone: 85251111116,
        destination_location: [56.8766894, 120.9891416],
        destination_street_address: "Castle Road",
        pickup_contact_name: "Swati",
        pickup_contact_phone: "+85251111118",
        pickup_location: [22.5029632, 114.1277213],
        pickup_street_address: "Road",
        scheduled_at: nil,
        vehicle_type: "van"
      }
    }

    it 'should trigger Gogox Service' do
      mock_object = instance_double(Gogox, book: gogox_booking_response)
      allow(Gogox).to receive(:new).with(order_attributes)
          .and_return(mock_object)
      expect(transport.book.metadata).to eq(gogox_booking_response)
    end
  end

  context "status" do
    it 'should trigger Gogox Service' do
      allow(Gogox).to receive(:transport_status).with(gogox_booking_id)
          .and_return(gogox_booking_response)
      expect(transport.status).to eq(transport_order)
    end
  end

  context "cancel" do
    it 'should trigger Gogox Service' do
      allow(Gogox).to receive(:cancel_order).with(gogox_booking_id)
          .and_return({
            order_uuid: gogox_booking_id,
            status: "cancelled"
          })
      expect(transport.cancel).to eq(transport_order)
    end
  end

end

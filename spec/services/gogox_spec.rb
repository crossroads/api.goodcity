require "rails_helper"

describe Gogox do

  let(:name)         { "John Roy" }
  let(:mobile)       { "+85210002000" }
  let(:pickupTime)   { "Wed, 30 Dec 2020 15:10:08.000000000 +0800" }
  let(:district)     { (create :district) }
  let(:vehicle)      { "van" }
  let(:params)       {
    {
      'district_id' => district.id,
    }
  }

  let(:gogovan) { Gogox.new(attributes) }

  let(:attributes) {
    {
      district_id: district.id,
      vehicle: vehicle,
      pickup_scheduled_at: pickupTime,
      params: params
    }
  }

  context "initialization" do
    it "pickupTime" do
      expect(gogovan.time).to eql(pickupTime)
    end
    it "district_id" do
      expect(gogovan.district_id).to eql(district.id)
    end
    it "vehicle" do
      expect(gogovan.vehicle).to eql(vehicle)
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
        "pickup_scheduled_at": 1609312208,
        "pickup_location": [district.latitude, district.longitude],
        "destination_location": [22.3748365, 113.9931416]
      }
    }

    it 'should trigger Gogox API' do
      mock_object = instance_double(GogoxApi::Transport, quotation: response)
      allow(GogoxApi::Transport).to receive(:new).with(params: quotation_attributes)
          .and_return(mock_object)
      expect(gogovan.quotation).to eq(response)
    end
  end

  context "book" do
    let(:gogovan) {
      Gogox.new({
        district_id: district.id,
        vehicle: vehicle,
        pickup_scheduled_at: pickupTime,
        params: params,
        pickup_contact_name: "David",
        pickup_contact_phone: "+85251111112",
        pickup_street_address: "Street"
      })
    }

    let(:response) {
      {
        "uuid" => "2f859363-5c43-4fe2-9b91-6c6c43d610d2",
        "status" => "pending",
        "vehicle_type" => "van",
        "payment_method" => "prepaid_wallet",
        "price" => {"amount" => 15000, "currency" => "HKD"},
        "price_breakdown" => [{"key" => "fee", "amount" => 15000}]
      }
    }

    let(:order_attributes) {
      {
        'vehicle_type': vehicle,
        "pickup_scheduled_at": 1609312208,
        "pickup_location": [district.latitude, district.longitude],
        "destination_location": [22.3748365, 113.9931416],
        "destination_contact_name": "Steve Kenworthy",
        "destination_contact_phone": "+85251111111",
        "destination_location": [22.3748365, 113.9931416],
        "destination_street_address": "Castle Peak Rd (So Kwun Wat)",
        "pickup_contact_name": "David",
        "pickup_contact_phone": "+85251111112",
        "pickup_street_address": "Street",
      }
    }

    it 'should trigger Gogox API' do
      mock_object = instance_double(GogoxApi::Transport, order: response)
      allow(GogoxApi::Transport).to receive(:new).with(params: order_attributes)
          .and_return(mock_object)
      expect(gogovan.book).to eq(response)
    end
  end

  describe 'parse_pickup_time' do
    context 'when pickup date is not specified' do
      it 'expects time to be in HKT' do
        expect(Gogox.new.send(:parse_pickup_time).zone).to eq('HKT')
      end

      it 'parse time to a DateTime object' do
        expect(Gogox.new.send(:parse_time).class).to eq(Integer)
      end
    end

    context 'when pickup date is specified' do
      it 'expects time to be in HKT' do
        expect(Gogox.new({ 'pickupTime' => Time.current.to_s }).send(:parse_pickup_time).zone).to eq('HKT')
      end

      it 'parse time to a DateTime object' do
        expect(Gogox.new({ 'pickupTime' => Time.current.to_s }).send(:parse_time).class).to eq(Integer)
      end
    end
  end

end

require 'rails_helper'

describe Api::V1::PrintersUserSerializer do

  let(:printers_user)  { create(:printers_user) }
  let(:serializer) { Api::V1::PrintersUserSerializer.new(printers_user).as_json }
  let(:json) { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    record = json['printers_user']
    expect(record['id']).to eq(printers_user.id)
    expect(record['printer_id']).to eq(printers_user.printer_id)
    expect(record['user_id']).to eq(printers_user.user_id)
  end
end

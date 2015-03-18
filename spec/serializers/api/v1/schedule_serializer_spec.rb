require 'rails_helper'

describe Api::V1::ScheduleSerializer do

  let(:schedule)   { build(:schedule) }
  let(:serializer) { Api::V1::ScheduleSerializer.new(schedule) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['schedule']['id']).to eql(schedule.id)
    expect(json['schedule']['slot']).to eql(schedule.slot)
    expect(json['schedule']['slot_name']).to eql(schedule.slot_name)
    expect(json['schedule']['scheduled_at'].to_date).
      to eql(schedule.scheduled_at.to_date)
  end
end
